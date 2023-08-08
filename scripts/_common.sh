#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

#=================================================
# PERSONAL HELPERS
#=================================================
rewrite_config_panel() {
    export apps=$(yunohost app list | grep "id\:" | sed "s/    id: //g")
    ynh_render_template /etc/yunohost/apps/chatonsinfo/config_panel.toml.j2 /etc/yunohost/apps/chatonsinfo/config_panel.toml
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
