# Load All Scripts
for script in $(
	here="$(dirname $0)"
	find "${here:?}/src/" -maxdepth 1 -type f \
		-name '*.sh' \
		-and -not -name '*.test.sh' \
); do
	. "$script"
done
