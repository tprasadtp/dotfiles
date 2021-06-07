# P0.Dependent: 00-fish-override.fish

if test -n "$NEMO_FISH_SHELL_DEBUG_LOAD"
  status --current-filename
end

if test $NEMO_FISH_SHELL_SUPPORTED -eq 1
    set -gx LMOD_ROOT /usr/share/lmod
    set -gx LMOD_PKG  /usr/share/lmod/lmod
    set -gx LMOD_DIR  /usr/share/lmod/lmod/libexec
    set -gx LMOD_CMD  /usr/share/lmod/lmod/libexec/lmod
    set -gx MODULESHOME /usr/share/lmod/lmod
    set -gx MODULERCFILE /opt/bwhpc/common/etc/modulerc
    set -gx LMOD_RC /opt/bwhpc/common/etc/nemo_lmodrc.lua
    set -gx LMOD_SITE_MSG_FILE /opt/bwhpc/common/etc/nemo_msgs.lua

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

    if test -z "$MANPATH"
        set -xg MANPATH ":"
    end

    set -gx MANPATH (/usr/share/lmod/lmod/libexec/addto MANPATH /usr/share/lmod/lmod/share/man)

    if status -i
    function module
        eval $LMOD_CMD fish $argv | source -
    end
    else
    function module
        eval $LMOD_CMD --no_redirect fish $argv | source -
    end
    end

    function ml
    eval $LMOD_DIR/ml_cmd $argv | source -
    end

    function clearMT
    eval $LMOD_DIR/clearMT_cmd bash | source -
    end

    # Module paths for fr_fr
    # This is invalid for other groups!
    set -gx MODULEPATH \
        (/usr/share/lmod/lmod/libexec/addto \
        --append MODULEPATH \
        /opt/bwhpc/modulefiles/applications/info \
        /opt/bwhpc/modulefiles/applications/fr \
        /opt/bwhpc/modulefiles/applications/common\
        /opt/bwhpc/modulefiles/libraries/info \
        /opt/bwhpc/modulefiles/libraries/fr \
        /opt/bwhpc/modulefiles/libraries/common \
        /opt/bwhpc/modulefiles/development/info \
        /opt/bwhpc/modulefiles/development/fr \
        /opt/bwhpc/modulefiles/development/common \
        /opt/bwhpc/modulefiles/obsolete/info \
        /opt/bwhpc/modulefiles/obsolete/fr \
        /opt/bwhpc/modulefiles/obsolete/common )

    # Module Alias
    alias ml='module'
end
