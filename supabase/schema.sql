create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  customer_name text not null,
  phone text not null,
  address text not null,
  items jsonb not null,
  total numeric(12,2) not null default 0,
  status text not null default 'pending',
  created_at timestamptz not null default now()
);
alter table public.orders enable row level security;

create table if not exists public.products (
  id text primary key,
  name text not null,
  category text not null,
  price numeric(12,2) not null,
  color text not null default '#171717',
  description text,
  image_url text,
  active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.products enable row level security;
create policy "public can view active products" on public.products for select using (active = true);

insert into public.products (id,name,category,price,color,description) values
('tee-black','Jomtub Essential Tee','เสื้อยืด',390,'#171717','เสื้อยืดทรงสบาย สีดำ'),
('sport-orange','Jomtub Active Jersey','เสื้อกีฬา',590,'#f05a28','เสื้อกีฬาแห้งไว สีส้ม'),
('team-white','Custom Team Jersey','เสื้อทีม',650,'#d8d7d2','เสื้อทีมสำหรับทุกแมตช์'),
('tee-green','Everyday Logo Tee','เสื้อยืด',420,'#68756a','เสื้อยืดใส่ได้ทุกวัน'),
('sport-navy','Move Training Top','เสื้อกีฬา',550,'#263746','เสื้อซ้อมน้ำหนักเบา'),
('team-yellow','Jomtub Team Edition','เสื้อทีม',690,'#e8c744','เสื้อทีมรุ่นพิเศษ')
on conflict (id) do nothing;

alter table public.orders add column if not exists order_no text;
alter table public.orders add column if not exists transfer_date date;
alter table public.orders add column if not exists transfer_amount numeric(12,2);
alter table public.orders add column if not exists payment_note text;
alter table public.orders add column if not exists payment_status text not null default 'unpaid';
alter table public.orders add column if not exists user_id uuid references auth.users(id) on delete set null;
create index if not exists orders_user_id_idx on public.orders(user_id);

drop policy if exists "public can create orders" on public.orders;
drop policy if exists "anonymous can create guest orders" on public.orders;
create policy "anonymous can create guest orders" on public.orders for insert to anon with check (user_id is null);

update public.products set image_url='/images/product-black-opt.png' where id='tee-black';
update public.products set image_url='/images/product-orange-opt.png' where id='sport-orange';
update public.products set image_url='/images/product-white-opt.png' where id='team-white';
update public.products set image_url='/images/product-green-opt.png' where id='tee-green';
update public.products set image_url='/images/product-navy-opt.png' where id='sport-navy';
update public.products set image_url='/images/product-yellow-opt.png' where id='team-yellow';

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists (select 1 from public.admin_users where user_id = auth.uid() and is_active = true); $$;

drop policy if exists "admins can manage products" on public.products;
create policy "admins can manage products" on public.products for all to authenticated using (public.is_admin()) with check (public.is_admin());
drop policy if exists "admins can view orders" on public.orders;
create policy "admins can view orders" on public.orders for select to authenticated using (public.is_admin());
drop policy if exists "admins can update orders" on public.orders;
create policy "admins can update orders" on public.orders for update to authenticated using (public.is_admin()) with check (public.is_admin());

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text,
  full_name text,
  phone text,
  default_address text,
  member_level text not null default 'Member',
  points integer not null default 0,
  total_spent numeric(12,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.profiles enable row level security;
drop policy if exists "users view own profile" on public.profiles;
create policy "users view own profile" on public.profiles for select to authenticated using (user_id = auth.uid() or public.is_admin());
drop policy if exists "users insert own profile" on public.profiles;
create policy "users insert own profile" on public.profiles for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "users update own profile" on public.profiles;
create policy "users update own profile" on public.profiles for update to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());

create table if not exists public.cart_items (
  user_id uuid not null references auth.users(id) on delete cascade,
  product_id text not null references public.products(id) on delete cascade,
  quantity integer not null default 1 check (quantity > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, product_id)
);
alter table public.cart_items enable row level security;
drop policy if exists "users manage own cart" on public.cart_items;
create policy "users manage own cart" on public.cart_items for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "members can create own orders" on public.orders;
create policy "members can create own orders" on public.orders for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "members can view own orders" on public.orders;
create policy "members can view own orders" on public.orders for select to authenticated using (user_id = auth.uid() or public.is_admin());

create table if not exists public.point_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  points integer not null,
  note text,
  created_at timestamptz not null default now()
);
alter table public.point_transactions enable row level security;
drop policy if exists "users view own points" on public.point_transactions;
create policy "users view own points" on public.point_transactions for select to authenticated using (user_id = auth.uid() or public.is_admin());
create unique index if not exists point_transactions_order_reward_idx on public.point_transactions(order_id) where order_id is not null and points > 0;

create or replace function public.apply_member_reward()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  earned integer;
  new_total numeric(12,2);
  new_level text;
  inserted_count integer;
begin
  if new.user_id is null then return new; end if;
  if new.payment_status = 'paid' and coalesce(old.payment_status,'') <> 'paid' then
    earned := floor(new.total / 100)::integer;
    insert into public.point_transactions(user_id, order_id, points, note)
    values(new.user_id, new.id, earned, 'คะแนนจากคำสั่งซื้อ ' || coalesce(new.order_no,''))
    on conflict do nothing;
    get diagnostics inserted_count = row_count;
    if inserted_count = 0 then return new; end if;

    update public.profiles
      set points = points + earned,
          total_spent = total_spent + new.total,
          updated_at = now()
      where user_id = new.user_id
      returning total_spent into new_total;

    new_level := case
      when new_total >= 30000 then 'VIP'
      when new_total >= 10000 then 'Gold'
      when new_total >= 3000 then 'Silver'
      else 'Member'
    end;
    update public.profiles set member_level = new_level, updated_at = now() where user_id = new.user_id;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_apply_member_reward on public.orders;
create trigger trg_apply_member_reward
after update of payment_status on public.orders
for each row execute function public.apply_member_reward();
