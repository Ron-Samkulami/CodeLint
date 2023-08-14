
# CodeLint Target设置脚本
#
# Author Ron
# 2023-6-16

# 通过读取yml的配置，生成扫描Target

require 'xcodeproj'
require 'yaml'

# yaml配置文件名，默认放在脚本同级目录
$yaml_file_name = "code_lint.yml"
# codelint Target名称
$code_lint_target_name = "CodeLint"

######################################## FUNC ########################################
## FUNC: 输出带颜色日志
def log(msg)
    puts "\033[37m [INFO] #{msg} \033[0m\n" # white
end

def logSuccess(msg)
    puts "\033[32m [SUCCESS] #{msg} \033[0m\n" # green
end

def logWarning(msg)
    puts "\033[33m [WARN] #{msg} \033[0m\n" # yellow
end

def logError(msg)
    puts "\033[31m [ERROR] #{msg} \033[0m\n" # red
end

def logStep(msg)
    puts "\033[36m >> #{msg}  \033[0m\n" # blue
end

## FUNC: 查找目标Target
def find_target_in_proj(project, target_name)
    target = nil
    project.targets.each do |item|
        if item.name.eql?("#{target_name}") then
            target = item
        end
    end
    return target
end

######################################## Enterance ########################################

# 输入参数
#ARGV.each do |parm|
#    puts "脚本输入参数 #{parm}"
#end

#xcodeproj_path = ""
#if ARGV[0].nil? then
#    logError("ruby脚本未传入xcodeproj路径")
#else
#    xcodeproj_path = ARGV[0]
#end

# 脚本根路径
srcroot = File.dirname(__FILE__)

# 1、从yml文件读取配置
logStep("读取yml配置文件")
yaml_file_path = "#{srcroot}/#$yaml_file_name"
content = YAML.load(File.open("#{yaml_file_path}"))

xcodeproj_path = "#{srcroot}/#{content["xcodeproj"]}"
project = Xcodeproj::Project.open(xcodeproj_path)
log("Project：\t#{project.root_object.name}.xcodeproj")
# 脚本与工程的相对路径
relative_srcroot = srcroot.sub!("#{project.project_dir}", '')

target_name = content["target"]
target = find_target_in_proj(project, "#{target_name}")
if target.nil? then
    logError("Target不存在: #{target_name}")
else
    log("Target：\t#{target.name}")
end

use_OCLint = content["tools"]["OCLint"]
use_SwiftLint = content["tools"]["SwiftLint"]
reporter_html = content["reporter"] == "html" ? 1 : 0

log("OCLint：\t#{use_OCLint}")
log("SwiftLint：\t#{use_SwiftLint}")
log("reporter：\t#{content["reporter"]}")

# 2、检查是否已存在扫描Target，不存在才创建
logStep("创建CodeLint Target")
code_lint_target = find_target_in_proj(project, "#$code_lint_target_name")

if !code_lint_target.nil? then
    logError("已存在 #{$code_lint_target_name}，即将退出")
else
    log("自动创建 #{$code_lint_target_name}")
    # 创建Aggregate
    code_lint_target = Xcodeproj::Project::ProjectHelper.new_aggregate_target(project, $code_lint_target_name, :ios, "11.0")
    # 添加脚本Run Script Phase
    script_build_phase = code_lint_target.new_shell_script_build_phase if !code_lint_target.nil?
    if !script_build_phase.nil? then
        script_build_phase.shell_path = "/bin/bash -l"
        
        # 以下开始为Run Script脚本内容
        script_build_phase.shell_script = <<-MY_DOC
####################################################
# 配置
oclint_enabled=#{use_OCLint}\t\t# 开启OC扫描
swiftlint_enabled=#{use_SwiftLint}\t\t# 开启Swift扫描
generate_html=#{reporter_html}\t\t\t# 生成html
hide_notification=0\t\t# 显示相关通知

# 相关路径
codelint_root="${SRCROOT}#{relative_srcroot}/"
swiftlint_report_path="${codelint_root}/Report/swiftlint_report"

oclint_home="${codelint_root}/Tools/oclint_23.00/bin"
oclint_report_path="${codelint_root}/Report/oclint_report"
compile_commands_json_path="${oclint_report_path}/compile_commands.json"

timestamp=`date "+%Y-%m-%d-%H-%M-%S"`

# 执行oclint
do_oclint() {
    # 检查oclint可执行文件
    if [ ! -d ${oclint_home} ]; then
        echo "[ERROR] oclint丢失！"
    else
        # 检查创建oclint输出目录
        if [ ! -d ${oclint_report_path} ]; then
            mkdir -p "${oclint_report_path}"
        fi
        
        # 弹窗提示
        if [ ${hide_notification} == 0 ]; then
            osascript <<END
            display dialog "It takes few minutes for OCLint, please wait！" buttons {"OK"} default button 1 with icon stop with title "Tips"
END
        fi
        
        # 编译，这里用-project参数，使用-workspace可能会出现IO disk错误
        xcodebuild -project #{project.root_object.name}.xcodeproj -target #{target.name} -sdk iphoneos -configuration Debug clean build COMPILER_INDEX_STORE_ENABLE=NO | `which xcpretty` -r json-compilation-database -o $compile_commands_json_path
        
        # 解析编译结果
        cd $oclint_report_path
        if [ ${generate_html} == 1 ]; then
            # 结果输出到html中
            ${oclint_home}/oclint-json-compilation-database -e Pods -- -report-type html -o oclint_${timestamp}.html -rc CYCLOMATIC_COMPLEXITY=10 -rc LONG_CLASS=1000 -rc LONG_METHOD=50 -rc LONG_LINE=140 -rc LONG_VARIABLE_NAME=30 -rc SHORT_VARIABLE_NAME=1 -rc MAXIMUM_IF_LENGTH=5 -rc MINIMUM_CASES_IN_SWITCH=2 -rc NCSS_METHOD=30 -rc NESTED_BLOCK_DEPTH=5 -rc TOO_MANY_METHOD=30 -rc TOO_MANY_PARAMETERS=5 -max-priority-1 9999 -max-priority-2 9999 -max-priority-3 9999
            open ${oclint_report_path}/oclint_${timestamp}.html
        else
            # 结果显示在Xcode中
            ${oclint_home}/oclint-json-compilation-database -e Pods -- -report-type xcode -rc CYCLOMATIC_COMPLEXITY=10 -rc LONG_CLASS=1000 -rc LONG_METHOD=50 -rc LONG_LINE=140 -rc LONG_VARIABLE_NAME=30 -rc SHORT_VARIABLE_NAME=1 -rc MAXIMUM_IF_LENGTH=5 -rc MINIMUM_CASES_IN_SWITCH=2 -rc NCSS_METHOD=30 -rc NESTED_BLOCK_DEPTH=5 -rc TOO_MANY_METHOD=30 -rc TOO_MANY_PARAMETERS=5 -max-priority-1 9999 -max-priority-2 9999 -max-priority-3 9999
        fi
        
        # 弹窗提示
        if [ ${hide_notification} == 0 ]; then
            osascript <<END
            display dialog "OCLint done！" buttons {"OK"} default button 1 with title "Tips"
END
        fi
          
    fi
}

# 执行swiftlint
do_swiftlint() {
    # 检查swiftlint输出目录
    if [ ! -d ${swiftlint_report_path} ]; then
        mkdir -p "${swiftlint_report_path}"
    fi
    
    # 检查是否安装swiftlint
    if which swiftlint > /dev/null; then
        swiftlint
    else
        echo "warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint"
    fi
    
    # 扫描
    if [ ${generate_html} == 1 ]; then
        swiftlint lint --reporter html > ${swiftlint_report_path}/swiftlint_${timestamp}.html
        open ${swiftlint_report_path}/swiftlint_${timestamp}.html
    else
        swiftlint lint --reporter xcode
    fi
    
    # 弹窗提示
    if [ ${hide_notification} == 0 ]; then
        osascript <<END
        display dialog "SwiftLint done！" buttons {"OK"} default button 1 with title "Tips"
END
    fi
}

# 添加环境变量
if [[ $(sysctl -n machdep.cpu.brand_string) =~ "Apple" ]]; then
    export PATH="/opt/homebrew/bin:$PATH"
fi
 
cd ${SRCROOT}

if [ ${swiftlint_enabled} == 1 ]; then
    do_swiftlint
fi
   
if [ ${oclint_enabled} == 1 ]; then
    do_oclint
fi
####################################################
MY_DOC

    end

    # 保存工程
    project.save
end



