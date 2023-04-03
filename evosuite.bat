
rem Usage: <name of this script with extension> <path to project file> <path to config file> <path to seeds file> <rounds> <max_instances>
rem Ex: evosuite.bat projects.csv config.csv 1 2


@echo off

setlocal enabledelayedexpansion

rem Parameters
set "projects=%~1"
set "configurations=%~2"
set "SEEDS_FILE=%~3"
set "rounds=%~4"
set "max_instances=%~5"


rem Constants
set MEMORY=4000
set search_budget=120


rem Variables
set running_instances=0
set /a seed_index=0

IF EXIST "results" (
    echo results folder already exists
    exit /b 1
)


for /l %%i in (1,1,%rounds%) do (

    set round=%%i

    rem Loop over projects & classes
    for /f "skip=1 tokens=1,2 delims=," %%a in ('type "!projects!"') do (

        set project_name=%%a
        set class_name=%%b

        rem Loop over configurations
        for /f "skip=1 tokens=1,2 delims=," %%c in ('type "!configurations!"') do (
            
            rem Sets and removes double quotes from the config_name & config
            set config_name=%%c
            set config_name=!config_name:"=!
            set config=%%d
            set config=!config:"=!

            rem Removes semi colons from the config string
            set user_configuration=
            if defined config (
                for %%e in ("!config:;=" "!") do (
                    set user_configuration=!user_configuration! %%~e
                )
            )

            rem Waits until running instances are less than max_instances
            echo Waiting to run class !class_name! with configuration !config_name!...
            call :wait_turn

            rem Finds the seed value to use for the next execution
            call :seed_value


            rem Executes the test generation for this class & configuration
            echo Running class !class_name! with configuration !config_name! for round !round!.
            echo ---------------------------------------------------------------------------------

            rem Extracts project name in correct format
            for /f "tokens=1,2 delims=_" %%a in ("!project_name!") do (
                set project_jar=%%b
            )

            rem Makes dir for log file if not exists
            if not exist results/!config_name!/!project_name!/!class_name!/logs/round!round! (
                mkdir "results/!config_name!/!project_name!/!class_name!/logs/round!round!"
            )

            start "EvosuiteTestGeneration" cmd /c java ^
                 -Xmx4G ^
                 -jar evosuite-master-1.2.1-SNAPSHOT.jar ^
                 -mem !MEMORY! ^
                 -Dconfiguration_id=!config_name!!round! ^
                 -Dgroup_id=!project_name! ^
                 -class !class_name! ^
                 -seed !seed_value! ^
                 -target projects/!project_name!/!project_jar!.jar ^
                 -Doutput_variables="configuration_id,TARGET_CLASS,criterion,Coverage,BranchCoverage,CBranchCoverage,Total_Branches,Covered_Branches,Covered_Branches_Real,Total_Goals,Covered_Goals" ^
                 -Dcriterion="BRANCH:CBRANCH" ^
                 -Dtest_dir=results/!config_name!/!project_name!/!class_name!/tests/rounds/!round! ^
                 -Dsearch_budget=!search_budget! ^
                 -Dshow_progress=true ^
                 !user_configuration! ^| tee results/!config_name!/!project_name!/!class_name!/logs/round!round!/log.txt 
        )
    )
)


echo Waiting for all proccesses to finish...
:wait_all
for /f "tokens=1" %%g in ('tasklist /fi "WINDOWTITLE eq EvosuiteTestGeneration" ^| find /c "cmd.exe"') do (
    set running_instances=%%~g
)

if !running_instances! == 0 (
    echo Giving extra time to finish up...
    timeout /t 10 /nobreak >nul
    echo All finished.
    exit /b
) else ( 
    timeout /t 3 /nobreak >nul
    goto wait_all
)


:wait_turn
for /f "tokens=1" %%f in ('tasklist /fi "WINDOWTITLE eq EvosuiteTestGeneration" ^| find /c "cmd.exe"') do (
    set running_instances=%%~f
)
if !running_instances! geq !max_instances! (
    timeout /t 3 /nobreak >nul
    goto wait_turn
)
goto :eof


:seed_value
 for /f "delims=" %%u in ('more +^!seed_index! !SEEDS_FILE!') do (
    set seed_value=%%u
    set /a seed_index+=1
    goto :eof
)



endlocal
