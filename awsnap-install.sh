# https://unix.stackexchange.com/questions/170279/can-i-hook-into-the-cd-command
__cd_hook() {
		# create a PROPMT_COMMAND equivalent to store chpwd functions
	typeset -g CHPWD_COMMAND=""

	_chpwd_hook() {
		shopt -s nullglob

		local f

		# run commands in CHPWD_COMMAND variable on dir change
		if [[ "$PREVPWD" != "$PWD" ]]; then
			local IFS=$';'
			for f in $CHPWD_COMMAND; do
				"$f"
			done
			unset IFS
		fi
		# refresh last working dir record
		export PREVPWD="$PWD"
	}

	# add `;` after _chpwd_hook if PROMPT_COMMAND is not empty
	PROMPT_COMMAND="_chpwd_hook${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
}

__awsnap_locate() {
	# https://unix.stackexchange.com/questions/6463/find-searching-in-parent-directories-instead-of-subdirectories
	local awsnap_dir=$(pwd -P 2>/dev/null || command pwd)
	while [ ! -e "$awsnap_dir/.awsnap" ]; do
		awsnap_dir=${awsnap_dir%/*}
		if [ "$awsnap_dir" = "" ]; then break; fi
	done
	echo "${awsnap_dir}"
}

awsnap() {
  local awsnap_dir=$(__awsnap_locate)
	if [ -e "${awsnap_dir}/.awsnap" ]; then
		target_profile=$(cat "${awsnap_dir}/.awsnap" | sed '/^$/d')
		if ! command -v aws &>/dev/null; then
			return
		fi
		if ! aws configure get aws_access_key_id --profile "${target_profile}" &>/dev/null; then
			echo "This directory expected aws profile ${target_profile} which you have not yet configured."
			return
		fi
		export AWS_PROFILE="${target_profile}"
	fi
}

case "$SHELL" in
	*bash*)
		CHPWD_COMMAND="${CHPWD_COMMAND:+$CHPWD_COMMAND;}awsnap"
		;;
	*zsh*)
		add-zsh-hook chpwd awsnap
		;;
esac

awsnap