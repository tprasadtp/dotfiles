# -*- fish-shell-script -*-
########################################################################
#  This is the system wide source file for setting up
#  modules in Fish:
#
########################################################################

if test (id -u) -ne 0

    if test -z "$MODULEPATH_ROOT"

        if test -n "$USER"
            set -gx USER "$LOGNAME"  # make sure $USER is set
        end
        set -gx LMOD_sys (uname)

        set -gx MODULEPATH_ROOT "/usr/share/modulefiles"

        set MODULEPATH_INIT "/usr/share/lmod/lmod/init/.modulespath"

        if test -e "$MODULEPATH_INIT"
            for str in (cat "$MODULEPATH_INIT" | sed 's/#.*$//')  # Allow end-of-line comments.
                for dir in (/usr/bin/ls -d "$str")
                    set -gx MODULEPATH (/usr/share/lmod/lmod/libexec/addto --append MODULEPATH $dir)
                end
            end
        else
            set -xg MODULEPATH (/usr/share/lmod/lmod/libexec/addto --append MODULEPATH $MODULEPATH_ROOT/$LMOD_sys $MODULEPATH_ROOT/Core)
            set -xg MODULEPATH (/usr/share/lmod/lmod/libexec/addto --append MODULEPATH /usr/share/lmod/lmod/modulefiles/Core)
        end

        set -xg FISH_ENV /usr/share/lmod/lmod/init/fish

        #
        # If MANPATH is empty, Lmod is adding a trailing ":" so that
        # the system MANPATH will be found
        if test -z "$MANPATH"
            set -xg MANPATH ":"
        end

        set -gx MANPATH (/usr/share/lmod/lmod/libexec/addto MANPATH /usr/share/lmod/lmod/share/man)
    end
    source  /usr/share/lmod/lmod/init/fish >/dev/null # Module Support

end
