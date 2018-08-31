#include <spawn.h>
#include <signal.h>
#include <dlfcn.h>

/* Set platform binary flag */
#define FLAG_PLATFORMIZE (1 << 1)
void patch_setuidandplatformize() {
        void* handle = dlopen("/usr/lib/libjailbreak.dylib", RTLD_LAZY);
        if (!handle) return; // Reset errors
        dlerror();
        typedef void (*fix_setuid_prt_t)(pid_t pid);
        fix_setuid_prt_t setuidptr = (fix_setuid_prt_t)dlsym(handle, "jb_oneshot_fix_setuid_now");
        typedef void (*fix_entitle_prt_t)(pid_t pid, uint32_t what);
        fix_entitle_prt_t entitleptr = (fix_entitle_prt_t)dlsym(handle, "jb_oneshot_entitle_now");
        setuidptr(getpid()); setuid(0);
        const char *dlsym_error = dlerror();
        if (dlsym_error) {
                return;
        }
        entitleptr(getpid(), FLAG_PLATFORMIZE);
}

int main(int argc, char **argv, char **envp) {
        setuid(0);
        if(getuid() != 0) {
         patch_setuidandplatformize();
         setuid(0);
       }
        setuid(0);
        printf("uid: %d\n", getuid());
        NSLog(@"CURRENTUID: %d", getuid());
        pid_t pid;
        int status;
        const char *path[] = {"PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/X11:/usr/games", NULL};
        posix_spawn(&pid, "/usr/bin/dpkg", NULL, NULL, (char**)argv, (char**)path);
        waitpid(pid, &status, 0);
        return status;
}
