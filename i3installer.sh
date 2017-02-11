#!/usr/bin/env bash
source libsh/libError.sh
source i3variables_for_template
erreur $? "chargement variable template" $ESTOP
file_to_copy="i3status.conf plus config"

function prerequisite {
type py3status &>/dev/null
erreur $? "presence py3status" $ECONT "echo \"pensez a l installer\""
}
function create_dir {
typeset dir=$1
if [ ! -e $dir ];then
	mkdir $dir
	erreur $? "creation rep $dir" $ESTOP
fi
}
function template_to_config {
sed -e "s#__I3HOMEDIR__#${__I3HOMEDIR__}#g" -e "s#__I3SCREENSHOTDIR__#${__I3SCREENSHOTDIR__}#g" configTEMPLATE > config
}
function copy_files {
cp -r ${file_to_copy} ${__I3HOMEDIR__}
}
function remove_files {
for file in ${file_to_copy}
do
	rm ${__I3HOMEDIR__}${file}
	erreur $? "supression $file" $ECONT
done
}
function i3uninstall {
remove_files
echo "please remove dir ${__I3HOMEDIR__} and ${__I3SCREENSHOTDIR__} manually if needed"
}
function i3install {
prerequisite
create_dir ${__I3HOMEDIR__}
create_dir ${__I3SCREENSHOTDIR__}
template_to_config
erreur $? "creation config file" $ESTOP
copy_files
erreur $? "installation" $ESTOP "i3uninstall"
}

i3install
