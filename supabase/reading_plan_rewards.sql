-- Atomic reward claim for reading plans.
-- Creates a RPC + trigger to prevent double-claim.

alter table public.user_reading_plan_progress
add column if not exists reward_claimed_at timestamptz;

create or replace function public.claim_reading_plan_reward(
  p_plan_id integer,
  p_xp_amount integer default 0,
  p_coin_amount integer default 0
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_progress_id integer;
  v_total_days integer;
  v_completed_days integer;
begin
  v_user_id := auth.uid();
  if v_user_id is null then
    raise exception 'Not authenticated';
  end if;

  select id
    into v_progress_id
  from public.user_reading_plan_progress
  where user_profile_id = v_user_id
    and reading_plan_id = p_plan_id
  for update;

  if v_progress_id is null then
    return false;
  end if;

  if exists (
    select 1
    from public.user_reading_plan_progress
    where id = v_progress_id
      and reward_claimed_at is not null
  ) then
    return false;
  end if;

  select duration_days
    into v_total_days
  from public.reading_plans
  where id = p_plan_id;

  if v_total_days is null or v_total_days = 0 then
    return false;
  end if;

  select count(distinct items.day_number)
    into v_completed_days
  from public.user_reading_plan_item_progress progress
  join public.reading_plan_items items
    on items.id = progress.reading_plan_item_id
  where progress.user_reading_plan_progress_id = v_progress_id;

  if v_completed_days < v_total_days then
    return false;
  end if;

  update public.user_reading_plan_progress
  set completed_at = coalesce(completed_at, now()),
      reward_claimed_at = now(),
      updated_at = now()
  where id = v_progress_id
    and reward_claimed_at is null
  returning id into v_progress_id;

  if v_progress_id is null then
    return false;
  end if;

  if coalesce(p_xp_amount, 0) > 0 then
    insert into public.xp_transactions (
      user_id,
      xp_amount,
      transaction_type,
      description,
      related_id
    )
    values (
      v_user_id,
      p_xp_amount,
      'reading_plan_completed',
      'Plano de leitura concluido',
      p_plan_id
    );
  end if;

  if coalesce(p_coin_amount, 0) <> 0 then
    update public.user_profiles
    set coins = coins + p_coin_amount,
        updated_at = now()
    where id = v_user_id;
  end if;

  return true;
end;
$$;

grant execute on function public.claim_reading_plan_reward(integer, integer, integer)
to authenticated;

create or replace function public.prevent_reward_claim_reset()
returns trigger
language plpgsql
as $$
begin
  if old.reward_claimed_at is not null
     and new.reward_claimed_at is distinct from old.reward_claimed_at then
    raise exception 'reward_claimed_at is immutable once set';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_prevent_reward_claim_reset
on public.user_reading_plan_progress;

create trigger trg_prevent_reward_claim_reset
before update of reward_claimed_at on public.user_reading_plan_progress
for each row
execute function public.prevent_reward_claim_reset();
