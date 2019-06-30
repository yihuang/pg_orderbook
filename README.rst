Proof of concept orderbook matching engine implemented in postgresql plpgsql.

Run
===

.. code-block:: bash

    $ psql postgres -c 'create database test_orderbook;'
    $ psql test_orderbook < schema.sql
    $ psql test_orderbook < functions.sql
    $ # populate order request data
    $ psql test_orderbook -c "insert into t_order_request select nextval('t_order_request_id_seq'), case when random() > 0.5 then 'buy'::side else 'sell'::side end, 1000 + random() * 100, 1000 + random() * 100, random() * 1000, now() from generate_series(1, 100000);"
    $ # process orders in batch
    $ psql test_orderbook -c 'select process_orders(1, 1000);'
    $ psql test_orderbook -c 'select count(*) from t_trades;'
