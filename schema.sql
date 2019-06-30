create type side as enum ('buy', 'sell');
create domain amount as decimal(33, 18);
create domain price as decimal(33, 18);
create table t_orders (
	id bigint not null,
	side Side not null,
	amount amount not null,
	deal_amount amount not null default 0,
	price price not null,
	user_id integer not null,
	done boolean not null default false, /* false: 未成交/部分成交, true: 完全成交/已撤销 */
	time timestamptz not null default now()
) partition by list (done);
create table t_order_history partition of t_orders for values in (true);
create table t_order_pending partition of t_orders for values in (false) partition by list (side);
create table t_order_bids partition of t_order_pending for values in ('buy') with (fillfactor=80);
create table t_order_asks partition of t_order_pending for values in ('sell') with (fillfactor=80);

CREATE INDEX t_order_pending_price_idx ON t_order_pending(price);
CREATE UNIQUE INDEX t_order_bids_id_idx ON t_order_bids(id);
CREATE UNIQUE INDEX t_order_asks_id_idx ON t_order_asks(id);

create table t_order_request (
	id bigserial,
	side Side not null,
	amount amount not null,
	price price not null,
	user_id integer not null,
	time timestamptz not null default now()
);
create table t_trades (
	id bigserial primary key,
	taker_id bigint not null,
	maker_id bigint not null,
	price price not null,
	amount amount not null,
	taker_done boolean not null,
	maker_done boolean not null,
	time timestamptz not null default now()
);
