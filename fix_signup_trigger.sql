-- 1. Create the function that will handle new user creation
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name, role, created_at)
  values (
    new.id, 
    new.raw_user_meta_data->>'full_name', 
    'user', 
    now()
  );
  return new;
end;
$$ language plpgsql security definer;

-- 2. Create the trigger to fire whenever a new user is added to auth.users
-- This ensures the profile is created automatically by the database (bypassing RLS issues)
create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
