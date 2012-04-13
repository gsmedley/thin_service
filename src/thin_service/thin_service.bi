'##################################################################
'# 
'# thin_service: Win32 native implementation for thin
'#                  (using ServiceFB and FreeBASIC)
'# 
'# Copyright (c) 2006 Multimedia systems
'# (c) and code by Luis Lavena
'# 
'#  thin_service (native) and thin_service gem_pluing are licensed
'#  in the same terms as thin, please review the thin license at
'#  http://thin.rubyforge.org/license.html
'#  
'##################################################################

'##################################################################
'# Requirements:
'# - FreeBASIC 0.18.
'# 
'##################################################################

#define SERVICEFB_INCLUDE_UTILS
#include once "ServiceFB.bi"
#include once "console_process.bi"

'# use for debug versions
#if not defined(GEM_VERSION)
  #define GEM_VERSION (debug mode)
#endif

'# preprocessor stringize
#define PPSTR(x) #x

namespace thin_service
    const VERSION as string = PPSTR(GEM_VERSION)
    
    '# namespace include
    using fb.svc
    using fb.svc.utils
    
    declare function single_onInit(byref as ServiceProcess) as integer
    declare sub single_onStart(byref as ServiceProcess)
    declare sub single_onStop(byref as ServiceProcess)
    
    '# SingleThin
    type SingleThin
        declare constructor()
        declare destructor()
        
        '# TODO: replace for inheritance here
        'declare function onInit() as integer
        'declare sub onStart()
        'declare sub onStop()
        
        __service       as ServiceProcess
        __console       as ConsoleProcess
        __child_pid     as uinteger
    end type
    
    '# TODO: replace with inheritance here
    dim shared single_thin_ref as SingleThin ptr
end namespace
