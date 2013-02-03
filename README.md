Hash::Simhash
=============

These modules can be used to find out how similar pieces of data are. In the `eg` directory you will find a sample implementation that picks out Java stack traces out of log files and figures out if they have already been "seen" before or not. Stack traces are represented by a hash and are stored across several (64) MySQL databases (the example uses localhost, with tables named `simhash_X`.

To create the tables:

    for i in $(seq 0 63); do mysql -A -uroot -pfoobar simhash -e "create table simhash_$i (hash bigint unsigned, data text, primary key (hash)) engine=innodb;"; done

Replace the username and password with yours.

To run the example:

    perl Makefile.PL
    make && sudo make install
    cat logfile | perl eg/stacksum

