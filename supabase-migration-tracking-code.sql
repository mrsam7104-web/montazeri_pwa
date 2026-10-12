-- Migration for existing Supabase project: switch customer lookup from phone to 4-digit tracking code.
-- Run in Supabase Dashboard > SQL Editor. Admin JSON records store trackingCode inside cars.
create or replace function public.lookup_vehicle_by_code(p_plate text, p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare row_car jsonb; wanted_plate text; wanted_code text; got_plate text; got_code text;
begin
 wanted_plate := replace(replace(replace(translate(lower(coalesce(p_plate,'')), '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩', '01234567890123456789'), ' ', ''), '-', ''), 'ـ', '');
 wanted_code := replace(replace(replace(translate(lower(coalesce(p_code,'')), '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩', '01234567890123456789'), ' ', ''), '-', ''), 'ـ', '');
 if wanted_plate = '' or wanted_code !~ '^\\d{4}$' then return null; end if;
 for row_car in select value from public.workshop_state s, jsonb_array_elements(s.cars) as value where s.id=1 loop
  got_plate := replace(replace(replace(translate(lower(coalesce(row_car->>'plate','')), '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩', '01234567890123456789'), ' ', ''), '-', ''), 'ـ', '');
  got_code := replace(replace(replace(translate(lower(coalesce(row_car->>'trackingCode','')), '۰۱۲۳۴۵۶۷۸۹٠١٢٣٤٥٦٧٨٩', '01234567890123456789'), ' ', ''), '-', ''), 'ـ', '');
  if got_plate = wanted_plate and got_code = wanted_code then return row_car; end if;
 end loop; return null;
end; $$;
revoke all on function public.lookup_vehicle_by_code(text,text) from public;
grant execute on function public.lookup_vehicle_by_code(text,text) to anon, authenticated;
