create or replace function limit_order_sell(id bigint, amount amount, price price, user_id integer) returns void as $$
declare
  cur cursor(p price) for select * from t_orders t where side='buy' and t.price >= p and done=false order by t.price desc for update;
  avail_amount amount;
  trade_amount amount;
begin
  for o in cur(price) loop
    avail_amount := o.amount - o.deal_amount;
    trade_amount := least(avail_amount, amount);
    update t_orders t set deal_amount=o.deal_amount + trade_amount, done=(avail_amount=trade_amount) where current of cur;
    amount := amount - trade_amount;
    -- insert trade
    insert into t_trades (taker_id, maker_id, price, amount, taker_done, maker_done)
                  values (id, o.id, o.price, trade_amount, amount=0, avail_amount=trade_amount);
    if amount=0 then
      exit;
    end if;
  end loop;

  insert into t_orders (id, side, amount, price, user_id, done)
                values (id, 'sell', amount, price, user_id, amount=0);
end;
$$ language plpgsql;

create or replace function limit_order_buy(id bigint, amount amount, price price, user_id integer) returns void as $$
declare
  cur cursor(p price) for select * from t_orders t where side='sell' and t.price <= p and done=false order by t.price for update;
  avail_amount amount;
  trade_amount amount;
begin
  for o in cur(price) loop
    avail_amount := o.amount - o.deal_amount;
    trade_amount := least(avail_amount, amount);
    update t_orders set deal_amount=o.deal_amount + trade_amount, done=(avail_amount=trade_amount) where current of cur;
    amount := amount - trade_amount;
    -- insert trade
    insert into t_trades (taker_id, maker_id, price, amount, taker_done, maker_done)
                  values (id, o.id, o.price, trade_amount, amount=0, avail_amount=trade_amount);
    if amount=0 then
      exit;
    end if;
  end loop;

  -- insert
  insert into t_orders (id, side, amount, price, user_id, done)
                values (id, 'buy', amount, price, user_id, amount=0);
end;
$$ language plpgsql;

create or replace function process_orders(order_begin integer, order_end integer) returns void as $$
declare
  o record;
begin
  for o in select * from t_order_request
                   where id >= order_begin
                     and id <= order_end loop
    if o.side = 'buy' then
      perform limit_order_buy(o.id, o.amount, o.price, o.user_id);
    else
      perform limit_order_sell(o.id, o.amount, o.price, o.user_id);
    end if;
  end loop;
end;
$$ language plpgsql;
