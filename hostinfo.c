#include <stdio.h>
#include <string.h>
#include <time.h>
#include <sys/utsname.h>

static void print_info(FILE *out)
{
	struct utsname u;
	char ts[64];
	time_t now = time(NULL);

	uname(&u);
	strftime(ts, sizeof(ts), "%Y-%m-%d %H:%M:%S %Z", localtime(&now));

	fprintf(out, "==== Environment info ====\n");
	fprintf(out, "Hostname : %s\n", u.nodename);
	fprintf(out, "Time     : %s\n", ts);
	fprintf(out, "OS       : %s %s\n", u.sysname, u.release);
	fprintf(out, "Version  : %s\n", u.version);
	fprintf(out, "Hardware : %s\n", u.machine);
	fprintf(out, "==========================\n");
}

int main(int argc, char *argv[])
{
	print_info(stdout);

	if (argc > 1) {
		FILE *chk = fopen(argv[1], "r");

		if (chk) {
			fclose(chk);
			fprintf(stderr, "WARNING: file '%s' exists, appending\n", argv[1]);
		}
		FILE *f = fopen(argv[1], "a");

		if (!f) {
			perror("fopen");
			return 1;
		}
		print_info(f);
		fclose(f);
	}
	return 0;
}
