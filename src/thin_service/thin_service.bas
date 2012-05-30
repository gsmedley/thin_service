'##################################################################
'# 
'# mongrel_service: Win32 native implementation for thin
'#                  (using ServiceFB and FreeBASIC)
'# 
'# Copyright (c) 2006 Multimedia systems
'# (c) and code by Luis Lavena
'# 
'#  mongrel_service (native) and mongrel_service gem_pluing are licensed
'#  in the same terms as mongrel, please review the mongrel license at
'#  http://thin.rubyforge.org/license.html

'#  
'##################################################################

'##################################################################
'# Requirements:
'# - FreeBASIC 0.18
'# 
'##################################################################

#include once "thin_service.bi"
#define DEBUG_LOG_FILE EXEPATH + "\thin_service.log"
#include once "_debug.bi"

namespace thin_service
    constructor SingleThin()
        dim redirect_path as string = EXEPATH
        dim redirect_file as string = "log/thin.service.log"
        dim flag as string
        dim idx as integer = 1

        '# determine supplied logfile
        flag = command(idx)
        do while (len(flag) > 0)
            '# application directory
            if (flag = "-c") or (flag = "--chdir") then
                redirect_path = command(idx + 1)
            end if

            '# log file
            if (flag = "-l") or (flag = "--log") then
                redirect_file = command(idx + 1)
            end if
            idx += 1

            flag = command(idx)
        loop

        with this.__service
            .name = "single"
            .description = "Thin Single Process service"
            
            '# disabling shared process
            .shared_process = FALSE
            
            '# TODO: fix inheritance here
            .onInit = @single_onInit
            .onStart = @single_onStart
            .onStop = @single_onStop
        end with
        
        with this.__console
            debug("redirecting to: " + redirect_path + "/" + redirect_file)
            .redirect(ProcessStdBoth, (redirect_path + "/" + redirect_file))
        end with
        
        '# TODO: fix inheritance here
        single_thin_ref = @this
    end constructor
    
    destructor SingleThin()
        '# TODO: fin inheritance here
    end destructor
    
    function single_onInit(byref self as ServiceProcess) as integer
        dim result as integer
        dim thin_cmd as string
        
        debug("single_onInit()")
        
        '# ruby.exe must be in the path, which we guess is already there.
        '# because thin_service executable (.exe) is located in the same
        '# folder than thin_rails ruby script, we complete the path with
        '# EXEPATH + "\thin_rails" to make it work.
        '# FIXED ruby installation outside PATH and inside folders with spaces
        thin_cmd = !"\"" + EXEPATH + !"\\ruby.exe" + !"\" " + !"\"" + EXEPATH + !"\\thin_service" + !"\"" 
        
        '# due lack of inheritance, we use single_thin_ref as pointer to 
        '# SingleThin instance. now we should call StillAlive
        self.StillAlive()
        if (len(self.commandline) > 0) then
            '# assign the program
            single_thin_ref->__console.filename = thin_cmd
            single_thin_ref->__console.arguments = self.commandline
            
            '# fix commandline, it currently contains params to be passed to
            '# thin_rails, and not ruby.exe nor the script to be run.
            self.commandline = thin_cmd + " " + self.commandline
            
            '# now launch the child process
            debug("starting child process with cmdline: " + self.commandline)
            single_thin_ref->__child_pid = 0
            if (single_thin_ref->__console.start() = true) then
                single_thin_ref->__child_pid = single_thin_ref->__console.pid
            end if
            self.StillAlive()
            
            '# check if pid is valid
            if (single_thin_ref->__child_pid > 0) then
                '# it worked
                debug("child process pid: " + str(single_thin_ref->__child_pid))
                result = not FALSE
            end if
        else
            '# if no param, no service!
            debug("no parameters was passed to this service!")
            result = FALSE
        end if
        
        debug("single_onInit() done")
        return result
    end function
    
    sub single_onStart(byref self as ServiceProcess)
        debug("single_onStart()")
        
        do while (self.state = Running) or (self.state = Paused)
            '# instead of sitting idle here, we must monitor the pid
            '# and re-spawn a new process if needed
            if not (single_thin_ref->__console.running = true) then
                '# check if we aren't terminating
                if (self.state = Running) or (self.state = Paused) then
                    debug("child process terminated!, re-spawning a new one")
                    
                    single_thin_ref->__child_pid = 0
                    if (single_thin_ref->__console.start() = true) then
                        single_thin_ref->__child_pid = single_thin_ref->__console.pid
                    end if
                    
                    if (single_thin_ref->__child_pid > 0) then
                        debug("new child process pid: " + str(single_thin_ref->__child_pid))
                    end if
                end if
            end if
            
            '# wait for 5 seconds
            sleep 5000
        loop
        
        debug("single_onStart() done")
    end sub
    
    sub single_onStop(byref self as ServiceProcess)
        debug("single_onStop()")
        
        '# now terminates the child process
        if not (single_thin_ref->__child_pid = 0) then
            debug("trying to kill pid: " + str(single_thin_ref->__child_pid))
            if not (single_thin_ref->__console.terminate() = true) then
                debug("Terminate() reported a problem when terminating process " + str(single_thin_ref->__child_pid))
            else
                debug("child process terminated with success.")
                single_thin_ref->__child_pid = 0
            end if
        end if
        
        debug("single_onStop() done")
    end sub
    
    sub application()
        dim simple as SingleThin
        dim host as ServiceHost
        dim ctrl as ServiceController = ServiceController("Thin Windows Service", "version " + VERSION, _
                                                            "(c) 2006-2010 The Mongrel development team.")
        
        '# add SingleThin (service)
        host.Add(simple.__service)
        select case ctrl.RunMode()
            '# call from Service Control Manager (SCM)
            case RunAsService:
                debug("ServiceHost RunAsService")
                host.Run()
                
            '# call from console, useful for debug purposes.
            case RunAsConsole:
                debug("ServiceController Console")
                ctrl.Console()
                
            case else:
                ctrl.Banner()
                print "thin_service is not designed to run form commandline,"
                print "please use thin_rails service:: commands to create a win32 service."
        end select
    end sub
end namespace

'# MAIN: start native thin_service here
thin_service.application()
