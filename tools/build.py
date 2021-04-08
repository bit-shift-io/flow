#!/usr/bin/env python3
#-*- coding: utf-8 -*-

import os
import sys
import subprocess
import inspect
import multiprocessing
import shutil
import getpass
import json
import datetime
import time
import pathlib

config = {
    'display_name': 'flow',
    'exeName': 'flow',
    'itchName': 'flow',
    'engine_branch': 'master',
    'engine_commit': '', # commit hash to a known stable build
    'cpuCount': multiprocessing.cpu_count(),
    'logToFile': True,
    
    'paths': {
        'tools': pathlib.Path(os.path.abspath(os.getcwd())),
        'project': pathlib.Path(os.path.abspath('../')),
        'build': pathlib.Path(os.path.abspath('../build')),
        'engine': pathlib.Path(os.path.abspath('../build/godot')),
        'osxcross': pathlib.Path(os.path.abspath('../build/osxcross')),
        'editor_docs': pathlib.Path(os.path.abspath('../editor_docs'))
    },
    
    'sdks': {
        'android': os.path.abspath(os.path.join(os.path.expanduser("~"), 'Android/Sdk')),
        'android_ndk': os.path.abspath(os.path.join(os.path.expanduser("~"), 'Android/Sdk/ndk-bundle')),
        'osxcross': os.path.abspath('../build/osxcross'),
        'steamworks_tools': os.path.abspath('steamworks_tools')
    },
    
    'args': {
        'linux': sys.platform.startswith('linux'),
        'windows': sys.platform.startswith('win32'),
        'mac': sys.platform.startswith('darwin'),
        'android': False,
        
        'demo': False,
        'full': False,
        'editor': False
    }
}

room = None
steam_username = None
steam_password = None

def main():
    menu = {}
    menu['1'] = ['Checkout/Update Engine from GIT', 'checkout_or_update_engine']
    menu['2'] = ['Compile Engine/Editor', 'compile_engine']
    menu['3'] = ['Build release exes', 'build_release_exes']
    menu['4'] = ['Package release data (will revert uncommited changes to Source dir)', 'package_release_data']
    menu['5'] = ['Run Unit Tests', 'run_unit_tests']
    menu['6'] = ['Make Editor Docs', 'build_editor_docs']
    menu['s'] = ['Steam Upload', 'steam_upload']
    menu['i'] = ['Itch Upload', 'itch_upload']
    menu['a'] = ['All the things - Build data/exes, unit test then upload', 'all_the_things']
    menu['c'] = ['Engine Clean', 'engine_clean']
    menu['d'] = ['Install dependencies', 'install_dependencies']
    menu['v'] = ['Get Vulkan libs (for macOS)', 'get_vulkan_libs']

    print('\n********************************************')
    print(config['args'])
    print(get_git_and_build_stats())
    print('')
    for item in menu:
        print (' ' + item + '. ' + menu[item][0])
        
    selection = str(input('> '))
    # check if in menu
    if selection in menu:
        eval(menu[selection][1] + '()')

    # check if its an arg
    if selection in config['args']:
        config['args'][selection] = not config['args'][selection]

    # exec function
    if '()' in selection:
        eval(selection)

    main()
    return

def process_template(src_file_path, dst_file_path, dictionary):
    #log("process_template " + src_file_path + " to " + dst_file_path + " with " + json.dumps(dictionary))
    
    with open(src_file_path, 'r') as file:
        data = file.read()

    for key, value in dictionary.items():
        #print("replacing " + '${' + key + '}' + " with " + value)
        data = data.replace('${' + key.upper() + '}', value)

    with open(dst_file_path, 'w') as file:
        file.write(data)
        #log("writing to " + dst_file_path + ": " + data);

    return

    
def install_dependencies():
    log("install_dependencies")
    if sys.platform.startswith('darwin'):
        run('brew install scons')
    else:
        log("OS not yet supported")


def get_vulkan_libs():
    # just grab the vulkan libs for mac
    # https://github.com/godotengine/godot/issues/47715#issuecomment-815556402
    # destination: /path/to/Godot.app/Contents/Frameworks/
    vulkan_sdk_version = "1.2.170.0"
    run("""
        curl -LO "https://sdk.lunarg.com/sdk/download/{0}/mac/vulkansdk-macos-{0}.dmg"
        hdiutil attach "vulkansdk-macos-{0}.dmg"
        cp "/Volumes/vulkansdk-macos-{0}/macOS/lib/libMoltenVK.dylib" {1}/godot/bin
        cp -r "/Volumes/vulkansdk-macos-{0}/macOS/share/vulkan/icd.d" {1}/godot/bin/vulkan
    """.format(vulkan_sdk_version, config['paths']['project']))
    log("Done. Remember to edit the MoltenVK_icd.json to remove one ../ before commiting")
    return


def build_release_exes():
    log("build_release_exes")

    def copy_libs_and_scripts(platform, platform_name, exe_ext, library_ext, target_dir_name, script_ext):
        # TODO: x86_64-w64-mingw32-strip on windows exe
        params = {'cwd': config['paths']['engine']}
        run('cp {0}/bin/*{1} {2}/{3}/'.format(config['paths']['engine'], library_ext, config['paths']['build'], target_dir_name), params)
        # special handling to generate a shell script to launch our app (needed for steam + editor)
        dst_file_path = '{0}/{1}/{2}_{3}{4}'.format(config['paths']['build'], target_dir_name, config['exeName'], platform_name, script_ext)
        process_template('{0}/templates/LaunchTemplate_{1}{2}'.format(config['paths']['tools'], platform_name, script_ext), dst_file_path, 
            { 'exe_name': '{0}_{1}{2}'.format(config['exeName'], platform_name, exe_ext), 'exe_args': '--editor' if target_dir_name == 'Editor' else '' })
        run('chmod +x {0}'.format(dst_file_path), params)
        return True
    
    def build_exe(platform, platform_name, exe_ext, library_ext, script_ext, target_dir_name, build_args):
        params = { 'cwd': config['paths']['engine'], 'show_output': True, 'show_cmd': True }
        dockerParams = {'platform': platform, **params}

        optimised = ".opt"
        target="release"

        # to ship/run with debug builds:
        optimised = ".debug"
        target = "debug"

        # special case for editor
        if (target_dir_name == "Editor"):
            optimised = ".tools"
            if (target == "release"):
                target = "release_debug"


        exe_name = 'godot.{0}{1}.64{2}'.format(platform, optimised, exe_ext)
        exe_path = config['paths']['engine'] / "bin" / exe_name

        run('rm {0}'.format(exe_path), params) # remove exe if it exists so we can determine if scons fails
        run('mkdir -p {0}'.format(config['paths']['build'] / target_dir_name), params)
        run('scons -j {0} platform={1} target={2} bits=64 use_static_cpp=yes builtin_openssl=yes modio=no {3}'.format(config['cpuCount'], platform, target, build_args), dockerParams)

        if not os.path.exists(exe_path):
            matrix_msg("FAIL: Failed to build {0} for {1} {2}".format(exe_name, platform_name, target_dir_name))
            return False

        run('cp {0} {1}/{2}/{3}_{4}{5}'.format(exe_path, config['paths']['build'], target_dir_name, config['exeName'], platform_name, exe_ext), params)
        return copy_libs_and_scripts(platform, platform_name, exe_ext, library_ext, target_dir_name, script_ext)

    def build_targets_internal(platform, platform_name, exe_ext, library_ext, script_ext):
        if config['args']['demo']:
            if not build_exe(platform, platform_name, exe_ext, library_ext, script_ext, "Demo", "demo=yes tools=no"):
                return False

        if config['args']['full']:
            if not build_exe(platform, platform_name, exe_ext, library_ext, script_ext, "Full", "demo=no tools=no"):
                return False
        
        if config['args']['editor']:
            if not build_exe(platform, platform_name, exe_ext, library_ext, script_ext, "Editor", "demo=no tools=yes"):
                return False

        return True

    def build_targets(platform, platform_name, exe_ext, library_ext, script_ext):
        # try to build, but if we hit a error, try a clean then build
        if not build_targets_internal(platform, platform_name, exe_ext, library_ext, script_ext):
            print("\nEngine failed to compile, trying a clean and then we will try again\n")
            engine_clean()
            return build_targets_internal(platform, platform_name, exe_ext, library_ext, script_ext)

        return True

        
    if config['args']['linux']:
        if not build_targets("linuxbsd", "Linux", '', '.so', ".sh"):
            return False

    if config['args']['windows']:
        if not build_targets("windows", "Windows", '.exe', '.dll', ".bat"):
            return False

    if config['args']['mac']: 
        if not build_targets("osx", "Mac", '', '.dylib', ".sh"):
            return False

    # clean the build to avoid build problems when trying to build after a docker build
    #params = {'cwd': config['paths']['engine']}
    #run('scons -c'.format(exe_path), params)

    return True


def engine_clean():
    log("engine_clean")
    params = { 'cwd': config['paths']['engine'], 'show_output': True, 'show_cmd': True }
    run('scons -c', params)
    return True


# compile the engine for the current operating system only
def compile_engine(report_error=False):
    log("compile_engine")
    params = { 'cwd': config['paths']['engine'], 'show_output': True, 'show_cmd': True }
    
    # nested function
    def build(platform, platform_dir_prefix, exe_ext, library_ext, args = ''):
        log("Building engine for: " + platform_dir_prefix)

        # remove old exe
        exe_path = '{0}/bin/godot.{1}.tools.64{2}'.format(config['paths']['engine'], platform, exe_ext)
        if (os.path.exists(exe_path)):
            os.remove(exe_path) #run('rm {0}'.format(exe_path))

        # this command is built on the native system so we do not need any LD_PRELOAD trickery as python doesn't like running things this way!
        # so we need a platform specific build of tools to be able to package up game data
        log("Compiling using scons...")
        run('scons -j {0} platform={1} bits=64 use_static_cpp=yes builtin_openssl=yes verbose=yes modio=no {2}'.format(config['cpuCount'], platform, args), params)
        run('cp {0}/bin/*{2} {1}/src/'.format(config['paths']['engine'], config['paths']['project'], library_ext), params)

        # verify exe built
        if not os.path.exists(exe_path):
            log("compile_engine FAIL: Tools exe not built " + exe_path)
            matrix_msg("FAIL: Tools exe not built")
            return False

        return True


    if sys.platform.startswith('linux'):
        if not build("linuxbsd", "Linux", '', '.so'):
            return False

    # scons -j2 platform=windows bits=64 use_static_cpp=yes builtin_openssl=yes verbose=yes modio=no vsproj=yes
    if sys.platform.startswith('win32'): 
        if not build("windows", "Windows", '.exe', '.dll', "vsproj=yes"):
            return False

    if sys.platform.startswith('darwin'): 
        if not build("osx", "Mac", '', '.dylib'):
            return False

    return True
    

def checkout_or_update_engine():
    log("checkout_or_update_engine")
    
    if not os.path.exists(config['paths']['engine']):
        run('mkdir -p {}'.format(config['paths']['build']))
        run('git clone --branch {} https://github.com/godotengine/godot.git {}'.format(config['engine_branch'], config['paths']['engine']))
    else:
        run('git -C {} checkout .'.format(config['paths']['engine']))
        run('git -C {} checkout {}'.format(config['paths']['engine'], config['engine_branch']))
        run('git -C {} pull'.format(config['paths']['engine']))
    
    # checkout a particular commit we know is stable (if working in unstable branch)
    if (len(config['engine_commit']) > 0):
        print("CHECKING OUT REVISION: " + config['engine_commit']);
        run('git -C {0} checkout {1}'.format(config['paths']['engine'], config['engine_commit']))

    run('ln -s {}/godot/modules/bitshift {}/modules'.format(config['paths']['project'], config['paths']['engine']), {'show_output': True})
    
    # copy binaries - this is of osx, we copy the vulkan files into the bun directory
    # so we can run the app from there
    bin_dir = '{0}/godot/bin'.format(config['paths']['project'])
    godot_bin_dir = '{0}/bin'.format(config['paths']['engine'])
    run('mkdir -p {0}'.format(godot_bin_dir))
    log('cp -r {0}/ {1}'.format(bin_dir, godot_bin_dir))
    run('cp -r {0}/ {1}'.format(bin_dir, godot_bin_dir), { 'show_output': True, 'show_cmd': True, 'cwd': config['paths']['engine'] })

    # apply patches
    patch_dir = '{0}/godot/patches'.format(config['paths']['project'])
    if os.path.exists(patch_dir):
        log("\nApplying patches")
        for filename in os.listdir(patch_dir):
            if (filename.startswith(".")):
                continue

            log("\nApplying patch: " + filename)
            patch_file = os.path.join(patch_dir, filename)
            run('git apply --ignore-whitespace -v {0}'.format(patch_file), { 'show_output': True, 'show_cmd': True, 'cwd': config['paths']['engine'] })
        
    # setup project for IDE's
    #run('./qt_create_project.sh', {'cwd': config['paths']['tools']})
    setup_vscode()

    # if we fail to compile, try a clean first
    #if not compile_engine(report_error=False):
    #    print("\nEngine failed to compile, trying a clean and then we will try again\n")
    #    engine_clean()
    #    return compile_engine(report_error=True)

    return True


def setup_vscode():
    dst_dir = '{}/.vscode'.format(config['paths']['engine'])
    src_dir = '{}/vscode'.format(config['paths']['tools'])
    log("vscode\n from: {}\n to: {}".format(src_dir, dst_dir))
    
    mk_dir = dst_dir + '/'
    if not os.path.exists(mk_dir):
        os.makedirs(mk_dir)
        log(" make dir: {}".format(mk_dir))
        
    for filename in os.listdir(src_dir):
        src_file = os.path.join(src_dir, filename)
        shutil.copy(src_file, dst_dir)
    return


def build_editor_docs():
    run('make html', {'cwd': config['paths']['editor_docs']})
    return


def steam_login():
    global steam_username, steam_password
    steam_username = input('steam username: ')
    steam_password = getpass.getpass('steam password: ')

    params = { 'cwd': config['sdks']['steamworks_tools'], 'show_output': True, 'show_cmd': False }
    stdout = run('./builder_linux/steamcmd.sh +login {0} {1} +quit'.format(steam_username, steam_password), params)

    #print("STEAM LOGIN OUTPUT:\n" + str(stdout))

    if ("FAILED login" in str(stdout)):
        log("Invalid steam user or pass, try again...")
        steam_login()
    
    return


def steam_upload():
    if (steam_username is None or steam_password is None):
        steam_login()

    params = { 'cwd': config['sdks']['steamworks_tools'], 'show_output': True, 'show_cmd': False }

    if config['args']['demo']:
        run('./builder_linux/steamcmd.sh +login {} {} +run_app_build_http ../demo_scripts/app_build_878040.vdf +quit'.format(steam_username, steam_password), params)
    
    if config['args']['full']:
        run('./builder_linux/steamcmd.sh +login {} {} +run_app_build_http ../full_scripts/app_build_878030.vdf +quit'.format(steam_username, steam_password), params)

    if config['args']['editor']:
        run('./builder_linux/steamcmd.sh +login {} {} +run_app_build_http ../editor_scripts/app_build_1148800.vdf +quit'.format(steam_username, steam_password), params)
    return


def itch_upload():
    params = { 'cwd': config['paths']['tools'], 'show_output': True, 'show_cmd': True }
    if not os.path.exists('{}/butler'.format(config['paths']['tools'])):
        run('wget https://dl.itch.ovh/butler/linux-amd64/head/butler', params)
        run('chmod +x butler', params)
        
    run('./butler upgrade --assume-yes', params)
    
    def upload():
        if config['args']['full']:
            run('./butler push ../Build/Full/ bitshift/{}:full'.format(config['itchName']), params)
        
        if config['args']['demo']:
            run('./butler push ../Build/Demo/ bitshift/{}:demo'.format(config['itchName']), params)

        if config['args']['editor']:
            run('./butler push ../Build/Editor/ bitshift/{}:editor'.format(config['itchName']), params)
    
    if config['args']['linux'] and config['args']['windows']: upload()
    else: log("to upload to itch you need windows, linux specified as well as either/and: demo, full or editor")
    return

# compute build version from the repo and return a dictionary with components
def get_git_and_build_stats():
    # handle versioning
    
    # run the command to get number of commits in the current branch:
    # git rev-list HEAD | wc -l
    p1 = subprocess.Popen(['git', 'rev-list', 'HEAD'], stdout=subprocess.PIPE)
    p2 = subprocess.Popen(['wc', '-l'], stdin=p1.stdout, stdout=subprocess.PIPE)
    p1.stdout.close()  # Allow p1 to receive a SIGPIPE if p2 exits.
    commit_count,err = p2.communicate()

    # run command to get the commit revision:
    # git rev-parse HEAD
    p3 = subprocess.Popen(['git', 'rev-parse', '--short', 'HEAD'], stdout=subprocess.PIPE)
    head_revision,err = p3.communicate()

    p4 = subprocess.Popen(['git', 'rev-parse', '--abbrev-ref', 'HEAD'], stdout=subprocess.PIPE)
    branch,err = p4.communicate()

    # run the command to get the latest tag from the current branch:
    # git describe --abbrev=0 --tags
    #p4 = subprocess.Popen(['git', 'describe', '--abbrev=0', '--tags'], stdout=subprocess.PIPE)
    #version_tag,err = p4.communicate()

    return {
        "build_number": commit_count.decode('utf-8').replace('\n', ''),
        "build_date": datetime.date.today().strftime('%Y-%m-%d'),
        "branch": branch.decode('utf-8').replace('\n', '')
    }


def package_release_data():
    log("package_release_data")
    
    content_package_name = 'Content.pck' # change to .zip for debugging contents
    params = { 'cwd': config['paths']['engine'], 'show_output': True, 'show_cmd': True }

    if not os.path.exists('{}/bin/godot.linuxbsd.tools.64'.format(config['paths']['engine'])):
        log("package_release_data FAIL: Tools exe not found")
        matrix_msg("FAIL: Tools exe not found")
        return False

    # copy from the project Source dir to some where in the build dir
    # deletes maps and mods as these are handled differently
    def copy_source_data(dest_dir_name):
        run('mkdir -p {0}'.format(config['paths']['build'] / dest_dir_name), params)
        run('cp -Lr {}/src/. {}/{}'.format(config['paths']['project'], config['paths']['build'], dest_dir_name), params)
        #run('rm -r {}/{}/UnitTest'.format(config['paths']['build'], dest_dir_name), params)

        godot_file = '{}/{}/project.godot'.format(config['paths']['build'], dest_dir_name)
        process_template(godot_file, godot_file, get_git_and_build_stats())


    # given a dir in the build dir, package it up
    def package_into_dir(src_dir_name, dest_dir_name, pck_name):
        src_dir = config['paths']['build'] / src_dir_name
        dest_dir = config['paths']['build'] / dest_dir_name
        run('mkdir -p {0}'.format(dest_dir), params)
        

    def copy_tmp_into_dir(dest_dir_name):
        dest_dir = config['paths']['build'] / dest_dir_name
        run('mkdir -p {0}'.format(dest_dir), params)
        run('cp -Lr {}/src/. {}'.format(config['paths']['project'], dest_dir_name), params)

    # remove gumpf user files
    def clean_files_from(dir_name):
        dir_path = '{}/{}'.format(config['paths']['build'], dir_name)
        run('rm -r {}/User'.format(dir_path), params)
        run('rm -r {}/.cache'.format(dir_path), params)
        run('rm {}/override.cfg'.format(dir_path), params)
        run('rm {}/*.sh'.format(dir_path), params)

    # copy LICENSE.md and set up an empty User folder
    def setup_special_files_and_dirs(dir_name):
        dir_path = config['paths']['build'] / dir_name
        run('mkdir -p {0}'.format(dir_path / "User"), params)
        run('touch {}/User/.gdignore'.format(dir_path), params)
        run('cp {}/src/LICENSE.md {}'.format(config['paths']['project'], dir_path), params)

    def package_game():
        #copy_source_data('tmp/content')
        #clean_files_from('tmp/content')

        # undo any changes in the repo WARNING: this will delete un-commieted changes!
        # and delete override so projects.godot doesnt get infected
        run('git -C {0}/src checkout .'.format(config['paths']['project']), { 'cwd': config['paths']['project'], 'show_output': True, 'show_cmd': True })
        run('rm {0}/src/override.cfg'.format(config['paths']['project']), params)

        # tweak project.godot
        godot_file = '{0}/src/project.godot'.format(config['paths']['project'])
        process_template(godot_file, godot_file, get_git_and_build_stats())

        # run the editor over the whole content (with mods and maps) to ensure import files updated, use a pck as its quicker than zip?
        run('{0}/bin/godot.linuxbsd.tools.64 --path {1}/src --export "Linux/X11" {2}/tmp/tmp_content.pck'.format(config['paths']['engine'], config['paths']['project'], config['paths']['build']), params)

        # package up the game
        run('{0}/bin/godot.linuxbsd.tools.64 --path {1}/src -s Editor/Package.gd -outdir={2}/tmp/'.format(config['paths']['engine'], config['paths']['project'], config['paths']['build']), params)

        # again revert any changes we made (to project.godot)
        run('git -C {0}/src checkout .'.format(config['paths']['project']), { 'cwd': config['paths']['project'], 'show_output': True, 'show_cmd': True })

    def copy_content(dest_dir_name):
        dest_dir = config['paths']['build'] / dest_dir_name
        run('mkdir -p {0}'.format(dest_dir), params)
        run('cp {0}/tmp/{1} {2}/{3}/{4}'.format(config['paths']['build'], content_package_name, config['paths']['build'], dest_dir_name, content_package_name), params)

    if config['args']['demo'] or config['args']['full']:
        package_game()

    if config['args']['demo']:
        copy_content('Demo')

        # copy demo maps
        run('mkdir -p {0}'.format(config['paths']['build'] / "Demo/Maps"), params)
        run('cp {}/tmp/Maps/Hawaii.pck {}/Demo/Maps'.format(config['paths']['build'], config['paths']['build']), params)
        run('cp {}/tmp/Maps/Tutorial.pck {}/Demo/Maps'.format(config['paths']['build'], config['paths']['build']), params)

        setup_special_files_and_dirs('Demo')
        
    if config['args']['full']:
        copy_content('Full')

        # copy maps and mods
        run('mkdir -p {0}/Full/Maps'.format(config['paths']['build']), params)
        run('mkdir -p {0}/Full/Mods'.format(config['paths']['build']), params)
        run('cp {0}/tmp/Maps/*.pck {1}/Full/Maps'.format(config['paths']['build'], config['paths']['build']), params)
        run('cp {0}/tmp/Mods/*.pck {1}/Full/Mods'.format(config['paths']['build'], config['paths']['build']), params)

        setup_special_files_and_dirs('Full')
        
    if config['args']['editor']:
        copy_source_data('Editor')
        # remove .import & .modio
        run('rm -r {}/Editor/.import'.format(config['paths']['build']), params)
        run('rm -r {}/Editor/.modio'.format(config['paths']['build']), params)
        clean_files_from('Editor')

        # copy editor/mod documentation into editor
        build_editor_docs()
        run('mkdir -p {0}/Editor/Docs'.format(config['paths']['build']), params)
        run('\cp -r {0}/_build/html/* {1}/Editor/Docs'.format(config['paths']['editor_docs'], config['paths']['build']), params)



    return True


def run_unit_tests():
    # run unit tests, abort if failure and report to matrix (if doing all the things)
    log("run_unit_tests")

    params = { 'cwd': '{0}/Full'.format(config['paths']['build']), 'show_output': True, 'show_cmd': True }
    stdout = run('./TrainsAndThings_Linux -s=UnitTest/UnitTestMgr.gd', params)

    print("UNIT TEST OUTPUT:\n" + str(stdout))

    if ("QUIT WITH SUCCESS" in str(stdout)):
        log("Unit tests are ok!")
        run('rm User/*', params)
        return True

    matrix_msg("FAIL: Unit Tests failed. Check Build/Full/User for output results.")
    return False


def all_the_things():
    from matrix_client.client import MatrixClient
    
    global config
    config['args'] = {
        'linux': True,
        'windows': True,
        'mac': False,
        'android': False,
        
        'demo': True,
        'full': True,
        'editor': True
    }
    
    def ret_error(p_shutdown):
        if (p_shutdown):
            time.sleep(10)
            run("systemctl poweroff")
            
        return False
            

    run('git pull --rebase --autostash') # ensure we pull the latest data

    stats = get_git_and_build_stats()
    print("")
    print(config['args'])
    print(stats)
    print("")

    upload = True
    shutdown = False

    if (stats["branch"] == "master"):
        upload = False
        proceed = str(input("WARNING: Uploading from MASTER branch is not intended. Proceeding will build but NOT upload. Proceed [Y/n]? "))
        if (proceed == 'n'):
            return ret_error(shutdown)

    shutdown = (str(input("Shutdown when complete [y/N]? ")) == 'y')
    
    if (upload):
        matrix_login()
        steam_login()

    start = time.time()
    engine_update_start = time.time();  

    if not checkout_or_update_engine():
        return ret_error(shutdown)

    engine_update_end = time.time(); 
    release_exes_start = time.time()   

    if not build_release_exes():
        return ret_error(shutdown)

    release_exes_end = time.time()
    package_data_start = time.time();  

    if not package_release_data():
        return ret_error(shutdown)

    package_data_end = time.time()
    unit_tests_start = time.time()

    if not run_unit_tests():
        return ret_error(shutdown)

    unit_tests_end = time.time()

    steam_upload_start = steam_upload_end = itch_upload_start = itch_upload_end = 0
    
    if (upload):

        steam_upload_start = time.time()

        steam_upload()

        steam_upload_end = time.time()
        itch_upload_start = time.time()

        itch_upload()

        itch_upload_end = time.time()

        msg = "SUCCESS: Build and deploy"
    else:
        msg = "SUCCESS: Build"

    end = time.time()
    matrix_msg("{0}. Time taken: {1}\n\tUpdating engine took: {2}\n\tBuilding exes took: {3}\n\tPackaging data took: {4}\n\tUnit tests took: {5}\n\tSteam upload took: {6}\n\tItch upload took: {7}".format(msg, 
        str(datetime.timedelta(seconds=end - start)),
        str(datetime.timedelta(seconds=engine_update_end - engine_update_start)), str(datetime.timedelta(seconds=release_exes_end - release_exes_start)),
        str(datetime.timedelta(seconds=package_data_end - package_data_start)),
        str(datetime.timedelta(seconds=unit_tests_end - unit_tests_start)),
        str(datetime.timedelta(seconds=steam_upload_end - steam_upload_start)),
        str(datetime.timedelta(seconds=itch_upload_end - itch_upload_start))
    ))

    if (shutdown):
        time.sleep(10)
        run("systemctl poweroff")

    return True


def matrix_msg(message):
    stats = get_git_and_build_stats()
    msg_prefix = "[" + config['display_name'] + " - v" + stats['branch'] + " b" + stats['build_number'] + " on " + stats['build_date'] + "] "
    log(msg_prefix + message)

    if (not room is None):
        room.send_text(msg_prefix + message)


def matrix_login():
    from matrix_client.client import MatrixClient
    
    global room
    client = MatrixClient("https://matrix.org")
    username = input('matrix username: ')
    if (username == ''):
        return

    password = getpass.getpass('matrix password: ')
    token = client.login(username=username, password=password)
    room = client.join_room("#bitshift:matrix.org")


def example_function():
    run('''
    echo "hi!"
    echo "rocks!"
    ls
    ''')
    
    get_root()
    write_file('/test.txt', '''
    [Unit]
    Description=mount swap

    [Swap]
    What=local_path

    [Install]
    WantedBy=multi-user.target
    ''')

    
    return




def log(str='', end='\n'):
    print(str, end=end, flush=True)
    if not config['logToFile']:
        return

    with open("log.txt", "a") as f:
        f.write(str + end)
    return
    

def get_root():
    if os.geteuid() != 0:
        #subprocess.call(['sudo', 'python3', *sys.argv])
        os.execvp('sudo', ['sudo', 'python3'] + sys.argv)
    return

    
def write_file(name, data):
    data = inspect.cleandoc(data)
    with open(name, 'w') as file:
        file.write(data)
    return


# run commands
# params:
# cwd
# show cmd
# returns the output
def run(command, params = {}):
    working_dir = os.getcwd()
    if 'cwd' in params:
        working_dir = params['cwd']

    # needs to be run via docker?
    platform = None
    if 'platform' in params:
        platform = params['platform']

    # linux builds need to go through the linux_build_env docker
    # mount working directory
    if platform == 'linuxbsd':
        # mount the project directory and the working directory
        # pas in the current user as an environment variable so the docker can run as this user to avoid permission problems
        symlinks = ' -v {0}:{0}'.format(config['paths']['project'])
        command = 'docker run {0} -v {1}:/working_volume -e LOCAL_USER_ID=`id -u $USER` {2} {3}'.format(symlinks, working_dir, 'linux_build_env', command)
        log("DOCKER CMD: " + command + "\n")

    # clean command
    cmd = inspect.cleandoc(command)
    
    # show output
    show_cmd = False
    if 'show_cmd' in params:
        show_cmd = params['show_cmd']

    if show_cmd:
        log(cmd + '\n')

    # https://www.endpoint.com/blog/2015/01/28/getting-realtime-output-using-python

    # exec
    proc = subprocess.Popen(cmd, shell=True, cwd=working_dir, env=os.environ, encoding='utf-8', stdout=subprocess.PIPE, stderr=subprocess.STDOUT)

    show_output = True
    if 'show_output' in params:
        show_output = params['show_output']

    stdout = []
    while True:
        output = proc.stdout.read(1)
        stdout.append(output)
        if len(output) == 0 and proc.poll() is not None:
            break
        if output and show_output:
            log(output, '')

    if platform == 'linuxbsd':
        log("DOCKER CMD COMPLETE!")

    return ''.join(stdout)


def sudo_exec(cmdline, passwd):
    osname = platform.system() # 1
    if osname == 'Linux':
        prompt = r'\[sudo\] password for %s: ' % os.environ['USER']
    elif osname == 'Darwin':
        prompt = 'Password:'
    else:
        assert False, osname

    child = pexpect.spawn(cmdline)
    idx = child.expect([prompt, pexpect.EOF], 3) # 2
    if idx == 0: # if prompted for the sudo password
        log.debug('sudo password was asked.')
        child.sendline(passwd)
        child.expect(pexpect.EOF)
    return child.before


if __name__ == '__main__':
    os.system('cls||clear')

    # remove old log
    if (os.path.exists("log.txt")):
        os.remove("log.txt")

    main()
