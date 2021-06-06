all:
	rm -rf src/*.beam *.beam  test_src/*.beam test_ebin controller_*;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf *_specs *_config *.log;
	echo Done
doc_gen:
	echo glurk not implemented
unit_test:
	rm -rf ebin/* src/*.beam *.beam test_src/*.beam test_ebin;
	rm -rf  *~ */*~  erl_cra*;
	rm -rf controller_*;
	rm -rf *_specs *_config *.log;
#	support
	mkdir test_ebin;
	cp ../support/src/support.app test_ebin;
	erlc -o test_ebin ../support/src/*.erl;
#	test application
	cp test_src/*.app test_ebin;
	erlc -o test_ebin test_src/*.erl;
	erl -pa ebin -pa test_ebin\
	    -setcookie abc\
	    -sname system_test\
	    -run unit_test start_test test_src/test.config
