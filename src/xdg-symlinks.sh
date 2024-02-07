xdg-symlinks() (
	cd "$HOME"
	local d
	for d in '.local' '.cache' '.config'; do
		if [ -d "./$d" ]; then
			echo "directory \`./$d\` is already exist."
			continue
		fi
		'command' 'ln' -s "xdg/$d" "./$d"
	done
)
