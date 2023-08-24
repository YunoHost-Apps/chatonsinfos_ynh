#!/bin/bash

#=================================================
# COMMON VARIABLES
#=================================================

#=================================================
# PERSONAL HELPERS
#=================================================
generate_config_panel() {
    export apps=$(yunohost app list | grep "id\:" | sed "s/ *id: //g")
    ynh_render_template /etc/yunohost/apps/chatonsinfo/conf/config_panel.toml.j2 /etc/yunohost/apps/chatonsinfo/config_panel.toml

    for app_id in $apps ;
    do
        app=${app_id%__*}
        if [ ! -e "$install_dir/public/${app_id}.properties" ]
        then
            cp "$install_dir/sources/MODELES/${app}.properties" "$install_dir/public/${app_id}.properties"
            #mkdir -p "$install_dir/public/${app_id}.di/subs"
            #mkdir "$install_dir/public/${app_id}.di/metrics"
            sed -i "/subs\.${app_id} =/d" "$install_dir/public/organization.properties"
            sed -i "/\[Subs\]/a \
subs.${app_id} = 'https://$domain$path/${app_id}.properties'" "$install_dir/public/organization.properties"
        fi
    done
    chown -R $app:www-data "$install_dir/public"
    chmod -R o-rwx "$install_dir"
    #chmod a-x "$install_dir/{public,sources}/*"
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
