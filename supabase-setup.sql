-- صافکاری منتظری: راه‌اندازی پایگاه‌داده مشترک Supabase
-- در Supabase Dashboard > SQL Editor یک New query باز کنید، کل این فایل را اجرا کنید.

create table if not exists public.workshop_state (
  id integer primary key check (id = 1),
  cars jsonb not null default '[]'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.workshop_state enable row level security;

-- رکورد اولیه را می‌سازد تا ذخیره‌های بعدی به‌صورت UPDATE همگام شوند.
insert into public.workshop_state (id, cars) values (1, '[]'::jsonb) on conflict (id) do nothing;

-- فقط کاربران واردشده (مدیر) اجازه دیدن/ویرایش رکورد اصلی را دارند.
drop policy if exists "admin can read workshop state" on public.workshop_state;
create policy "admin can read workshop state" on public.workshop_state for select to authenticated using ((auth.jwt()->>'email') = 'ADMIN_EMAIL_HERE');
drop policy if exists "admin can insert workshop state" on public.workshop_state;
create policy "admin can insert workshop state" on public.workshop_state for insert to authenticated with check ((auth.jwt()->>'email') = 'ADMIN_EMAIL_HERE');
drop policy if exists "admin can update workshop state" on public.workshop_state;
create policy "admin can update workshop state" on public.workshop_state for update to authenticated using ((auth.jwt()->>'email') = 'ADMIN_EMAIL_HERE') with check ((auth.jwt()->>'email') = 'ADMIN_EMAIL_HERE');

-- مشتری فقط با پلاک و موبایل تطبیق‌داده‌شده یک پرونده دریافت می‌کند؛ دسترسی مستقیم به جدول ندارد.
create or replace function public.lookup_vehicle_by_code(p_plate text, p_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  row_car jsonb;
  wanted_plate text;
  wanted_code text;
  got_plate text;
  got_code text;
begin
  wanted_plate := replace(replace(replace(translate(lower(coalesce(p_plate,'')), '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩', '01234567890123456789'), ' ', ''), '-', ''), 'ـ', '');
  wanted_code := replace(replace(replace(translate(lower(coalesce(p_code,'')), '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩', '01234567890123456789'), ' ', ''), '-', ''), 'ـ', '');
  if wanted_plate = '' or wanted_code !~ '^\d{4}$' then return null; end if;
  -- بررسی تک‌تک پرونده‌ها بدون افشای فهرست مشتریان
  for row_car in select value from public.workshop_state s, jsonb_array_elements(s.cars) as value where s.id=1 loop
    got_plate := replace(replace(replace(translate(lower(coalesce(row_car->>'plate','')), '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩', '01234567890123456789'), ' ', ''), '-', ''), 'ـ', '');
    got_code := replace(replace(replace(translate(lower(coalesce(row_car->>'trackingCode','')), '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩', '01234567890123456789'), ' ', ''), '-', ''), 'ـ', '');
    if got_plate = wanted_plate and got_code = wanted_code then return row_car; end if;
  end loop;
  return null;
end;
$$;

revoke all on function public.lookup_vehicle_by_code(text,text) from public;
grant execute on function public.lookup_vehicle_by_code(text,text) to anon, authenticated;

-- فعال کردن ارسال رویدادهای Realtime برای به‌روزرسانی صفحات باز
do $$ begin
  alter publication supabase_realtime add table public.workshop_state;
exception when duplicate_object then null; when others then null; end $$;
