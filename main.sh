# Load All Scripts
for script in $(
	find 'src/' -maxdepth 1 -type f \
		-name '*.sh' \
		-and -not -name '*.test.sh' \
); do
	. "$script"
done
