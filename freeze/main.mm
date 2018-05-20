#include <spawn.h>
#include <signal.h>
#include <dlfcn.h>

void patch_setuid() {
    void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
    if (!handle) 
        return;

    dlerror();
    typedef void (*fix_setuid_prt_t)(pid_t pid);
    fix_setuid_prt_t ptr = (fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");
    
    const char *dlsym_error = dlerror();
    if (dlsym_error) 
        return;

    ptr(getpid());
}

int main(int argc, char **argv, char **envp) {
	setuid(0);
	
	if(getuid() != 0) {
           patch_setuid();
	   setuid(0);
	}
	
	pid_t pid;
        int status;
	const char *path[] = {"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games", NULL};
        posix_spawn(&pid, "/usr/bin/dpkg", NULL, NULL, (char**)argv, (char**)path);
        waitpid(pid, &status, 0);
				return 0;
}
