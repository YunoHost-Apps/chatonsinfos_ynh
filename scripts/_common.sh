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

    create_service_properties
}

create_service_properties() {
    export apps=$(yunohost app list | grep "id\:" | sed "s/ *id: //g")
    for _app_id in $apps ;
    do
        _app=${_app_id%__*}
        local service_path="$install_dir/public/${_app_id}.properties"
        if [ ! -e "$service_path" ]
        then
            local source_path="$install_dir/sources/MODELES/service-${_app}.properties"
            if [ ! -e "$source_path" ]
            then
                source_path="$install_dir/sources/MODELES/service.properties"
            fi
            cp "$source_path" "$service_path"

            # Prefill the properties
            ynh_print_info --message="Filling service.properties"
            local app_info="$(yunohost app info $_app_id --full --json)"
            get_info() {
                cat $app_info | jq -r ".$1"
            }
            ynh_write_var_in_file --file="$service_path" --key="file.datetime" --value="$(date '+%Y-%m-%dT%H:%M:%S')"
            ynh_write_var_in_file --file="$service_path" --key="file.generator" --value="chatonsinfos_ynh"

            ynh_write_var_in_file --file="$service_path" --key="service.name" --value="$(get_info 'name')"
            ynh_write_var_in_file --file="$service_path" --key="service.description" --value="$(get_info 'description')"
            ynh_write_var_in_file --file="$service_path" --key="service.guide.technical" --value="$(get_info 'from_catalog.git.url')"
            ynh_write_var_in_file --file="$service_path" --key="service.website" --value="https://$(get_info 'domain_path')"
            ynh_write_var_in_file --file="$service_path" --key="service.startdate" --value="$(date '+%Y-%m-%dT%H:%M:%S')"
            ynh_write_var_in_file --file="$service_path" --key="service.status.level" --value="OK"
            local ldap="$(get_info 'manifest.integration.ldap')"
            local sso="$(get_info 'manifest.integration.sso')"
            local allowed="$(get_info 'permissions.allowed')"
            local registration="Member"
            if [[ "$allowed" == *"visitors"* &&  "$ldap" == "not_relevant"  &&  "$sso" == "not_relevant" ]]
            then
                registration="None"
            elif [[ "$allowed" == *"visitors"* && "$ldap" == "false" ]]
            then
                registration="Free"
            fi
            ynh_write_var_in_file --file="$service_path" --key="service.registration" --value="$registration"
            ynh_write_var_in_file --file="$service_path" --key="service.registration.load" --value="OPEN"
            ynh_write_var_in_file --file="$service_path" --key="service.install.type" --value="DISTRIBUTION"

            ynh_write_var_in_file --file="$service_path" --key="software.name" --value="$(get_info 'manifest.name')"
            ynh_write_var_in_file --file="$service_path" --key="software.website" --value="$(get_info 'manifest.upstream.website')"
            ynh_write_var_in_file --file="$service_path" --key="software.license.url" --value="https://spdx.org/licenses/$(get_info 'manifest.upstream.license').html"
            ynh_write_var_in_file --file="$service_path" --key="software.license.name" --value="$(get_info 'manifest.upstream.license')"
            #ynh_write_var_in_file --file="$service_path" --key="software.version" --value="$(get_info 'manifest.version')"
            ynh_write_var_in_file --file="$service_path" --key="software.source.url" --value="$(get_info 'manifest.upstream.code')"
            # TODO modules
            #ynh_write_var_in_file --file="$service_path" --key="software.modules" --value=""

            for config_key in host.name host.description host.server.distribution host.server.type host.provider.type host.provider.hypervisor host.country.name host.country.code
            do
                settings=${config_key//\./_}
                local value=$(ynh_app_setting_set --app=$app --key=$settings)
                ynh_write_var_in_file --file="$service_path" --key="$config_key" --value="$value"
            done
        fi
    done
    chown -R $app:www-data "$install_dir/public"
    chmod -R o-rwx "$install_dir"
    #chmod a-x "$install_dir/{public,sources}/*"
}
update_subs() {
    local app_published
    export apps=$(yunohost app list | grep "id\:" | sed "s/ *id: //g")
    local orga_path"$install_dir/public/organization.properties"
    
    # Remove all subs 
    sed -i "/^subs\..* =/d" "$orga_path"
    
    # Add a subs for each published apps
    for subs_app_id in $apps
    do
        local app_published=$(ynh_app_setting_get --app=$app --key=${subs_app_id}_published)
        if [ "$app_published" == "" ]
        then
            sed -i "/\[Subs\]/a \
subs.${subs_app_id} = 'https://$domain$path/${subs_app_id}.properties'" "$orga_path"
        fi
    done

    # Add external subs
    local external_subs=$(ynh_app_setting_get --app=$app --key=external_subs | sed "s/,/ /g")
    for external_sub in $external_subs
    do
        local subs_app_id=${external_sub%*:}
        local subs_url=${external_sub#*:}
        sed -i "/\[Subs\]/a \
subs.${subs_app_id} = '${subs_url}'" "$orga_path"

    done

    ynh_write_var_in_file --file="$orga_path" --key="file.datetime" --value="$(date '+%Y-%m-%dT%H:%M:%S')"
}

#=================================================
# EXPERIMENTAL HELPERS
#=================================================

#=================================================
# FUTURE OFFICIAL HELPERS
#=================================================
