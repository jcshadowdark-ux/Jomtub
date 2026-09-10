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
create policy "public can create orders" on public.orders for insert with check (true);

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

update public.products set image_url='/images/product-black-opt.png' where id='tee-black';
update public.products set image_url='/images/product-orange-opt.png' where id='sport-orange';
update public.products set image_url='/images/product-white-opt.png' where id='team-white';

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
