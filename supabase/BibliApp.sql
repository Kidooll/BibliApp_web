-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.achievements (
                                     id integer NOT NULL DEFAULT nextval('achievements_id_seq'::regclass),
                                     title character varying NOT NULL UNIQUE,
                                     description text NOT NULL,
                                     xp_reward integer NOT NULL DEFAULT 0,
                                     icon_name character varying,
                                     created_at timestamp with time zone DEFAULT now(),
                                     updated_at timestamp with time zone DEFAULT now(),
                                     achievement_code character varying NOT NULL UNIQUE,
                                     requirement_type character varying NOT NULL,
                                     requirement_value integer NOT NULL,
                                     is_active boolean NOT NULL DEFAULT true,
                                     CONSTRAINT achievements_pkey PRIMARY KEY (id)
);
CREATE TABLE public.bible_stories (
                                      id integer NOT NULL DEFAULT nextval('bible_stories_id_seq'::regclass),
                                      title character varying NOT NULL,
                                      audio_url character varying NOT NULL,
                                      text text,
                                      created_at timestamp with time zone DEFAULT now(),
                                      updated_at timestamp with time zone DEFAULT now(),
                                      CONSTRAINT bible_stories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.bookmarks (
                                  id integer NOT NULL DEFAULT nextval('bookmarks_id_seq'::regclass),
                                  bookmark_type USER-DEFINED NOT NULL,
                                  verse_id integer,
                                  devotional_id integer,
                                  note_text text,
                                  highlight_color character varying,
                                  created_at timestamp with time zone DEFAULT now(),
                                  updated_at timestamp with time zone DEFAULT now(),
                                  user_profile_id uuid,
                                  CONSTRAINT bookmarks_pkey PRIMARY KEY (id),
                                  CONSTRAINT bookmarks_devotional_id_fkey FOREIGN KEY (devotional_id) REFERENCES public.devotionals(id),
                                  CONSTRAINT bookmarks_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.books (
                              id integer NOT NULL DEFAULT nextval('books_id_seq'::regclass),
                              translation_id integer NOT NULL,
                              name character varying NOT NULL,
                              abbreviation character varying NOT NULL,
                              testament character varying NOT NULL,
                              order_in_testament integer NOT NULL,
                              created_at timestamp with time zone DEFAULT now(),
                              updated_at timestamp with time zone DEFAULT now(),
                              CONSTRAINT books_pkey PRIMARY KEY (id),
                              CONSTRAINT books_translation_id_fkey FOREIGN KEY (translation_id) REFERENCES public.translations(id)
);
CREATE TABLE public.challenge_participants (
                                               id uuid NOT NULL DEFAULT uuid_generate_v4(),
                                               challenge_id uuid,
                                               user_profile_id uuid,
                                               progress integer NOT NULL DEFAULT 0,
                                               completed boolean NOT NULL DEFAULT false,
                                               created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                               updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                               CONSTRAINT challenge_participants_pkey PRIMARY KEY (id),
                                               CONSTRAINT challenge_participants_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES public.community_challenges(id),
                                               CONSTRAINT challenge_participants_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.community_challenges (
                                             id uuid NOT NULL DEFAULT uuid_generate_v4(),
                                             title text NOT NULL,
                                             description text NOT NULL,
                                             type text NOT NULL CHECK (type = ANY (ARRAY['reading'::text, 'streak'::text, 'sharing'::text])),
                                             goal integer NOT NULL,
                                             start_date timestamp with time zone NOT NULL,
                                             end_date timestamp with time zone NOT NULL,
                                             created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                             updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                             CONSTRAINT community_challenges_pkey PRIMARY KEY (id)
);
CREATE TABLE public.daily_missions (
                                       id integer NOT NULL DEFAULT nextval('daily_missions_id_seq'::regclass),
                                       code text NOT NULL UNIQUE,
                                       title text NOT NULL,
                                       description text,
                                       xp_reward integer NOT NULL DEFAULT 5,
                                       coin_reward integer NOT NULL DEFAULT 0,
                                       frequency text NOT NULL DEFAULT 'daily'::text,
                                       is_active boolean NOT NULL DEFAULT true,
                                       created_at timestamp with time zone NOT NULL DEFAULT now(),
                                       CONSTRAINT daily_missions_pkey PRIMARY KEY (id)
);
CREATE TABLE public.devotional_bible_references (
                                                    id integer NOT NULL DEFAULT nextval('devotional_bible_references_id_seq'::regclass),
                                                    devotional_id integer NOT NULL,
                                                    verse_id integer NOT NULL,
                                                    created_at timestamp with time zone DEFAULT now(),
                                                    updated_at timestamp with time zone DEFAULT now(),
                                                    CONSTRAINT devotional_bible_references_pkey PRIMARY KEY (id),
                                                    CONSTRAINT devotional_bible_references_devotional_id_fkey FOREIGN KEY (devotional_id) REFERENCES public.devotionals(id),
                                                    CONSTRAINT devotional_bible_references_verse_id_fkey FOREIGN KEY (verse_id) REFERENCES public.verses(id)
);
CREATE TABLE public.devotional_emotional_categories (
                                                        id integer NOT NULL DEFAULT nextval('devotional_emotional_categories_id_seq'::regclass),
                                                        devotional_id integer NOT NULL,
                                                        emotional_category_id integer NOT NULL,
                                                        created_at timestamp with time zone DEFAULT now(),
                                                        updated_at timestamp with time zone DEFAULT now(),
                                                        CONSTRAINT devotional_emotional_categories_pkey PRIMARY KEY (id),
                                                        CONSTRAINT devotional_emotional_categories_devotional_id_fkey FOREIGN KEY (devotional_id) REFERENCES public.devotionals(id),
                                                        CONSTRAINT devotional_emotional_categories_emotional_category_id_fkey FOREIGN KEY (emotional_category_id) REFERENCES public.emotional_categories(id)
);
CREATE TABLE public.devotional_themes (
                                          id integer NOT NULL DEFAULT nextval('devotional_themes_id_seq'::regclass),
                                          subject character varying NOT NULL,
                                          type character varying,
                                          used boolean NOT NULL DEFAULT false,
                                          created_at timestamp with time zone DEFAULT now(),
                                          updated_at timestamp with time zone DEFAULT now(),
                                          CONSTRAINT devotional_themes_pkey PRIMARY KEY (id)
);
CREATE TABLE public.devotionals (
                                    id integer NOT NULL DEFAULT nextval('devotionals_id_seq'::regclass),
                                    title character varying NOT NULL,
                                    text text,
                                    audio_url character varying,
                                    published_date date NOT NULL,
                                    created_at timestamp with time zone DEFAULT now(),
                                    updated_at timestamp with time zone DEFAULT now(),
                                    citation text,
                                    author text,
                                    verse text,
                                    word text,
                                    reflection text,
                                    practical_application text,
                                    prayer text,
                                    verse1 text,
                                    verse2 text,
                                    CONSTRAINT devotionals_pkey PRIMARY KEY (id)
);
CREATE TABLE public.emotional_categories (
                                             id integer NOT NULL DEFAULT nextval('emotional_categories_id_seq'::regclass),
                                             name character varying NOT NULL UNIQUE,
                                             description text,
                                             created_at timestamp with time zone DEFAULT now(),
                                             updated_at timestamp with time zone DEFAULT now(),
                                             CONSTRAINT emotional_categories_pkey PRIMARY KEY (id)
);
CREATE TABLE public.levels (
                               id integer NOT NULL DEFAULT nextval('levels_id_seq'::regclass),
                               level_number integer NOT NULL UNIQUE,
                               xp_required integer NOT NULL,
                               created_at timestamp with time zone DEFAULT now(),
                               updated_at timestamp with time zone DEFAULT now(),
                               level_name character varying NOT NULL,
                               description text,
                               badge_icon character varying,
                               CONSTRAINT levels_pkey PRIMARY KEY (id)
);
CREATE TABLE public.motivational_messages (
                                              id integer NOT NULL DEFAULT nextval('motivational_messages_id_seq'::regclass),
                                              message text NOT NULL,
                                              category character varying NOT NULL,
                                              created_at timestamp with time zone DEFAULT now(),
                                              CONSTRAINT motivational_messages_pkey PRIMARY KEY (id)
);
CREATE TABLE public.podcast_episodes (
                                         id integer NOT NULL DEFAULT nextval('podcast_episodes_id_seq'::regclass),
                                         podcast_id integer NOT NULL,
                                         title character varying NOT NULL,
                                         audio_url character varying NOT NULL,
                                         description text,
                                         published_date timestamp with time zone,
                                         created_at timestamp with time zone DEFAULT now(),
                                         updated_at timestamp with time zone DEFAULT now(),
                                         CONSTRAINT podcast_episodes_pkey PRIMARY KEY (id),
                                         CONSTRAINT podcast_episodes_podcast_id_fkey FOREIGN KEY (podcast_id) REFERENCES public.podcasts(id)
);
CREATE TABLE public.podcasts (
                                 id integer NOT NULL DEFAULT nextval('podcasts_id_seq'::regclass),
                                 title character varying NOT NULL,
                                 description text,
                                 feed_url character varying,
                                 created_at timestamp with time zone DEFAULT now(),
                                 updated_at timestamp with time zone DEFAULT now(),
                                 CONSTRAINT podcasts_pkey PRIMARY KEY (id)
);
CREATE TABLE public.prayer_journal_entries (
                                               id integer NOT NULL DEFAULT nextval('prayer_journal_entries_id_seq'::regclass),
                                               entry_date date NOT NULL,
                                               title character varying,
                                               text text NOT NULL,
                                               created_at timestamp with time zone DEFAULT now(),
                                               updated_at timestamp with time zone DEFAULT now(),
                                               user_profile_id uuid,
                                               CONSTRAINT prayer_journal_entries_pkey PRIMARY KEY (id),
                                               CONSTRAINT prayer_journal_entries_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.read_devotionals (
                                         id integer NOT NULL DEFAULT nextval('read_devotionals_id_seq'::regclass),
                                         devotional_id integer NOT NULL,
                                         read_at timestamp with time zone NOT NULL,
                                         created_at timestamp with time zone DEFAULT now(),
                                         updated_at timestamp with time zone DEFAULT now(),
                                         user_profile_id uuid,
                                         read_date date,
                                         CONSTRAINT read_devotionals_pkey PRIMARY KEY (id),
                                         CONSTRAINT read_devotionals_devotional_id_fkey FOREIGN KEY (devotional_id) REFERENCES public.devotionals(id),
                                         CONSTRAINT read_devotionals_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.reading_plan_items (
                                           id integer NOT NULL DEFAULT nextval('reading_plan_items_id_seq'::regclass),
                                           reading_plan_id integer NOT NULL,
                                           day_number integer NOT NULL,
                                           verse_id integer,
                                           devotional_id integer,
                                           created_at timestamp with time zone DEFAULT now(),
                                           updated_at timestamp with time zone DEFAULT now(),
                                           CONSTRAINT reading_plan_items_pkey PRIMARY KEY (id),
                                           CONSTRAINT reading_plan_items_reading_plan_id_fkey FOREIGN KEY (reading_plan_id) REFERENCES public.reading_plans(id),
                                           CONSTRAINT reading_plan_items_verse_id_fkey FOREIGN KEY (verse_id) REFERENCES public.verses(id),
                                           CONSTRAINT reading_plan_items_devotional_id_fkey FOREIGN KEY (devotional_id) REFERENCES public.devotionals(id)
);
CREATE TABLE public.reading_plans (
                                      id integer NOT NULL DEFAULT nextval('reading_plans_id_seq'::regclass),
                                      title character varying NOT NULL,
                                      description text,
                                      duration_days integer NOT NULL,
                                      created_at timestamp with time zone DEFAULT now(),
                                      updated_at timestamp with time zone DEFAULT now(),
                                      CONSTRAINT reading_plans_pkey PRIMARY KEY (id)
);
CREATE TABLE public.reading_progress (
                                         id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
                                         plan_id bigint,
                                         day_number integer NOT NULL,
                                         completed boolean DEFAULT false,
                                         completed_at timestamp with time zone,
                                         created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                         updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                         CONSTRAINT reading_progress_pkey PRIMARY KEY (id),
                                         CONSTRAINT reading_progress_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES public.reading_plans(id)
);
CREATE TABLE public.reading_streaks (
                                        id integer NOT NULL DEFAULT nextval('reading_streaks_id_seq'::regclass),
                                        current_streak_days integer NOT NULL DEFAULT 0,
                                        last_active_date date,
                                        longest_streak_days integer NOT NULL DEFAULT 0,
                                        created_at timestamp with time zone DEFAULT now(),
                                        updated_at timestamp with time zone DEFAULT now(),
                                        user_profile_id uuid,
                                        CONSTRAINT reading_streaks_pkey PRIMARY KEY (id),
                                        CONSTRAINT reading_streaks_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.relaxation_sounds (
                                          id integer NOT NULL DEFAULT nextval('relaxation_sounds_id_seq'::regclass),
                                          title character varying NOT NULL,
                                          audio_url character varying NOT NULL,
                                          created_at timestamp with time zone DEFAULT now(),
                                          updated_at timestamp with time zone DEFAULT now(),
                                          CONSTRAINT relaxation_sounds_pkey PRIMARY KEY (id)
);
CREATE TABLE public.shares (
                               id uuid NOT NULL DEFAULT uuid_generate_v4(),
                               user_profile_id uuid,
                               type text NOT NULL CHECK (type = ANY (ARRAY['verse'::text, 'progress'::text, 'achievement'::text])),
                               content jsonb NOT NULL,
                               created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                               updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                               CONSTRAINT shares_pkey PRIMARY KEY (id),
                               CONSTRAINT shares_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.shop_items (
                                   id integer NOT NULL DEFAULT nextval('shop_items_id_seq'::regclass),
                                   name character varying NOT NULL UNIQUE,
                                   description text,
                                   cost_coins integer NOT NULL DEFAULT 0,
                                   cost_xp integer NOT NULL DEFAULT 0,
                                   item_type USER-DEFINED NOT NULL,
                                   image_url character varying,
                                   effect_data json,
                                   is_active boolean NOT NULL DEFAULT true,
                                   created_at timestamp with time zone DEFAULT now(),
                                   updated_at timestamp with time zone DEFAULT now(),
                                   CONSTRAINT shop_items_pkey PRIMARY KEY (id)
);
CREATE TABLE public.store_items (
                                    id uuid NOT NULL DEFAULT uuid_generate_v4(),
                                    name text NOT NULL,
                                    description text NOT NULL,
                                    type text NOT NULL CHECK (type = ANY (ARRAY['theme'::text, 'avatar'::text, 'background'::text, 'quote'::text])),
                                    price integer NOT NULL,
                                    image_url text,
                                    data jsonb NOT NULL,
                                    created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                    updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                    CONSTRAINT store_items_pkey PRIMARY KEY (id)
);
CREATE TABLE public.studies (
                                id integer NOT NULL DEFAULT nextval('studies_id_seq'::regclass),
                                title character varying NOT NULL,
                                content text NOT NULL,
                                type character varying,
                                tags ARRAY,
                                metadata jsonb,
                                created_at timestamp with time zone DEFAULT now(),
                                CONSTRAINT studies_pkey PRIMARY KEY (id)
);
CREATE TABLE public.study_tag_links (
                                        id integer NOT NULL DEFAULT nextval('study_tag_links_id_seq'::regclass),
                                        study_id integer NOT NULL,
                                        tag_id integer NOT NULL,
                                        CONSTRAINT study_tag_links_pkey PRIMARY KEY (id),
                                        CONSTRAINT study_tag_links_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.studies(id),
                                        CONSTRAINT study_tag_links_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.study_tags(id)
);
CREATE TABLE public.study_tags (
                                   id integer NOT NULL DEFAULT nextval('study_tags_id_seq'::regclass),
                                   name character varying NOT NULL UNIQUE,
                                   CONSTRAINT study_tags_pkey PRIMARY KEY (id)
);
CREATE TABLE public.translations (
                                     id integer NOT NULL DEFAULT nextval('translations_id_seq'::regclass),
                                     name character varying NOT NULL,
                                     abbreviation character varying NOT NULL,
                                     language character varying NOT NULL,
                                     created_at timestamp with time zone DEFAULT now(),
                                     updated_at timestamp with time zone DEFAULT now(),
                                     CONSTRAINT translations_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_achievements (
                                          id integer NOT NULL DEFAULT nextval('user_achievements_id_seq'::regclass),
                                          achievement_id integer NOT NULL,
                                          unlocked_at timestamp with time zone NOT NULL,
                                          created_at timestamp with time zone DEFAULT now(),
                                          updated_at timestamp with time zone DEFAULT now(),
                                          user_id uuid DEFAULT auth.uid(),
                                          CONSTRAINT user_achievements_pkey PRIMARY KEY (id),
                                          CONSTRAINT user_achievements_achievement_id_fkey FOREIGN KEY (achievement_id) REFERENCES public.achievements(id),
                                          CONSTRAINT user_achievements_user_profile_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.user_badges (
                                    id uuid NOT NULL DEFAULT uuid_generate_v4(),
                                    user_profile_id uuid NOT NULL,
                                    badge_type character varying NOT NULL CHECK (badge_type::text = ANY (ARRAY['streak'::character varying, 'reading'::character varying, 'level'::character varying, 'achievement'::character varying, 'challenge'::character varying, 'devotional'::character varying, 'prayer'::character varying, 'sharing'::character varying]::text[])),
  badge_name character varying NOT NULL,
  badge_description text,
  badge_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  display_order integer DEFAULT 0,
  is_visible boolean NOT NULL DEFAULT true,
  earned_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  CONSTRAINT user_badges_pkey PRIMARY KEY (id),
  CONSTRAINT user_badges_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.user_challenge_progress (
                                                id integer NOT NULL DEFAULT nextval('user_challenge_progress_id_seq'::regclass),
                                                user_profile_id uuid,
                                                challenge_id integer,
                                                current_progress integer DEFAULT 0,
                                                completed_at timestamp with time zone,
                                                created_at timestamp with time zone DEFAULT now(),
                                                updated_at timestamp with time zone DEFAULT now(),
                                                started_at timestamp with time zone,
                                                is_completed boolean DEFAULT false,
                                                CONSTRAINT user_challenge_progress_pkey PRIMARY KEY (id),
                                                CONSTRAINT user_challenge_progress_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id),
                                                CONSTRAINT user_challenge_progress_challenge_id_fkey FOREIGN KEY (challenge_id) REFERENCES public.weekly_challenges(id)
);
CREATE TABLE public.user_coins (
                                   id uuid NOT NULL DEFAULT uuid_generate_v4(),
                                   user_profile_id uuid,
                                   amount integer NOT NULL DEFAULT 0,
                                   created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                   updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                   CONSTRAINT user_coins_pkey PRIMARY KEY (id),
                                   CONSTRAINT user_coins_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.user_favorite_studies (
                                              id integer NOT NULL DEFAULT nextval('user_favorite_studies_id_seq'::regclass),
                                              study_id integer NOT NULL,
                                              favorited_at timestamp with time zone DEFAULT now(),
                                              user_profile_id uuid,
                                              CONSTRAINT user_favorite_studies_pkey PRIMARY KEY (id),
                                              CONSTRAINT user_favorite_studies_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.studies(id),
                                              CONSTRAINT user_favorite_studies_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.user_items (
                                   id uuid NOT NULL DEFAULT uuid_generate_v4(),
                                   user_profile_id uuid,
                                   store_item_id uuid,
                                   is_equipped boolean NOT NULL DEFAULT false,
                                   created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                   updated_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
                                   CONSTRAINT user_items_pkey PRIMARY KEY (id),
                                   CONSTRAINT user_items_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id),
                                   CONSTRAINT user_items_store_item_id_fkey FOREIGN KEY (store_item_id) REFERENCES public.store_items(id)
);
CREATE TABLE public.user_missions (
                                      id integer NOT NULL DEFAULT nextval('user_missions_id_seq'::regclass),
                                      user_id uuid,
                                      mission_id integer,
                                      mission_date date NOT NULL DEFAULT CURRENT_DATE,
                                      progress integer NOT NULL DEFAULT 0,
                                      target integer NOT NULL DEFAULT 1,
                                      status text NOT NULL DEFAULT 'pending'::text,
                                      completed_at timestamp with time zone,
                                      claimed_at timestamp with time zone,
                                      created_at timestamp with time zone NOT NULL DEFAULT now(),
                                      updated_at timestamp with time zone NOT NULL DEFAULT now(),
                                      CONSTRAINT user_missions_pkey PRIMARY KEY (id),
                                      CONSTRAINT user_missions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
                                      CONSTRAINT user_missions_mission_id_fkey FOREIGN KEY (mission_id) REFERENCES public.daily_missions(id)
);
CREATE TABLE public.user_preferences (
                                         user_profile_id uuid NOT NULL,
                                         morning_reminders boolean DEFAULT true,
                                         evening_reminders boolean DEFAULT true,
                                         achievement_reminders boolean DEFAULT true,
                                         challenge_reminders boolean DEFAULT true,
                                         created_at timestamp with time zone DEFAULT now(),
                                         updated_at timestamp with time zone DEFAULT now(),
                                         CONSTRAINT user_preferences_pkey PRIMARY KEY (user_profile_id),
                                         CONSTRAINT user_preferences_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.user_profiles (
                                      old_internal_id_int4 integer NOT NULL DEFAULT nextval('user_profiles_id_seq'::regclass),
                                      id uuid NOT NULL,
                                      username character varying UNIQUE,
                                      avatar_url character varying,
                                      total_devotionals_read integer NOT NULL DEFAULT 0,
                                      total_xp integer NOT NULL DEFAULT 0,
                                      current_level integer NOT NULL DEFAULT 1,
                                      xp_to_next_level integer NOT NULL DEFAULT 100,
                                      coins integer NOT NULL DEFAULT 0,
                                      weekly_goal integer NOT NULL DEFAULT 7,
                                      created_at timestamp with time zone DEFAULT now(),
                                      updated_at timestamp with time zone DEFAULT now(),
                                      last_weekly_reset date DEFAULT CURRENT_DATE,
                                      CONSTRAINT user_profiles_pkey PRIMARY KEY (id)
);
CREATE TABLE public.user_purchases (
                                       id integer NOT NULL DEFAULT nextval('user_purchases_id_seq'::regclass),
                                       shop_item_id integer NOT NULL,
                                       purchased_at timestamp with time zone NOT NULL DEFAULT now(),
                                       cost_coins_at_purchase integer NOT NULL,
                                       cost_xp_at_purchase integer NOT NULL,
                                       created_at timestamp with time zone DEFAULT now(),
                                       updated_at timestamp with time zone DEFAULT now(),
                                       user_profile_id uuid,
                                       CONSTRAINT user_purchases_pkey PRIMARY KEY (id),
                                       CONSTRAINT user_purchases_shop_item_id_fkey FOREIGN KEY (shop_item_id) REFERENCES public.shop_items(id),
                                       CONSTRAINT user_purchases_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.user_read_studies (
                                          id integer NOT NULL DEFAULT nextval('user_read_studies_id_seq'::regclass),
                                          study_id integer NOT NULL,
                                          read_at timestamp with time zone DEFAULT now(),
                                          user_profile_id uuid,
                                          CONSTRAINT user_read_studies_pkey PRIMARY KEY (id),
                                          CONSTRAINT user_read_studies_study_id_fkey FOREIGN KEY (study_id) REFERENCES public.studies(id),
                                          CONSTRAINT user_read_studies_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.user_reading_plan_item_progress (
                                                        id integer NOT NULL DEFAULT nextval('user_reading_plan_item_progress_id_seq'::regclass),
                                                        user_reading_plan_progress_id integer NOT NULL,
                                                        reading_plan_item_id integer NOT NULL,
                                                        completed_at timestamp with time zone NOT NULL,
                                                        created_at timestamp with time zone DEFAULT now(),
                                                        updated_at timestamp with time zone DEFAULT now(),
                                                        CONSTRAINT user_reading_plan_item_progress_pkey PRIMARY KEY (id),
                                                        CONSTRAINT user_reading_plan_item_progre_user_reading_plan_progress_i_fkey FOREIGN KEY (user_reading_plan_progress_id) REFERENCES public.user_reading_plan_progress(id),
                                                        CONSTRAINT user_reading_plan_item_progress_reading_plan_item_id_fkey FOREIGN KEY (reading_plan_item_id) REFERENCES public.reading_plan_items(id),
                                                        CONSTRAINT user_reading_plan_item_progress_user_reading_plan_progress_id_f FOREIGN KEY (user_reading_plan_progress_id) REFERENCES public.user_reading_plan_progress(id)
);
CREATE TABLE public.user_reading_plan_progress (
                                                   id integer NOT NULL DEFAULT nextval('user_reading_plan_progress_id_seq'::regclass),
                                                   reading_plan_id integer NOT NULL,
                                                   started_at timestamp with time zone NOT NULL,
                                                   completed_at timestamp with time zone,
                                                   created_at timestamp with time zone DEFAULT now(),
                                                   updated_at timestamp with time zone DEFAULT now(),
                                                   user_profile_id uuid,
                                                   CONSTRAINT user_reading_plan_progress_pkey PRIMARY KEY (id),
                                                   CONSTRAINT user_reading_plan_progress_reading_plan_id_fkey FOREIGN KEY (reading_plan_id) REFERENCES public.reading_plans(id),
                                                   CONSTRAINT user_reading_plan_progress_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.user_reminders (
                                       id integer NOT NULL DEFAULT nextval('user_reminders_id_seq'::regclass),
                                       user_profile_id uuid,
                                       reminder_time time without time zone NOT NULL,
                                       days ARRAY NOT NULL,
                                       message text NOT NULL,
                                       category character varying NOT NULL DEFAULT 'general'::character varying,
                                       is_active boolean DEFAULT true,
                                       created_at timestamp with time zone DEFAULT now(),
                                       updated_at timestamp with time zone DEFAULT now(),
                                       CONSTRAINT user_reminders_pkey PRIMARY KEY (id),
                                       CONSTRAINT user_reminders_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.user_stats (
                                   id integer NOT NULL DEFAULT nextval('user_stats_id_seq'::regclass),
                                   user_id uuid UNIQUE,
                                   total_devotionals_read integer DEFAULT 0,
                                   current_streak_days integer DEFAULT 0,
                                   longest_streak_days integer DEFAULT 0,
                                   total_highlights integer DEFAULT 0,
                                   chapters_read_count integer DEFAULT 0,
                                   last_activity_date date,
                                   last_sync_at timestamp with time zone DEFAULT now(),
                                   created_at timestamp with time zone DEFAULT now(),
                                   updated_at timestamp with time zone DEFAULT now(),
                                   CONSTRAINT user_stats_pkey PRIMARY KEY (id),
                                   CONSTRAINT user_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.users (
                              id integer NOT NULL DEFAULT nextval('users_id_seq'::regclass),
                              email character varying UNIQUE,
                              password_hash character varying,
                              created_at timestamp with time zone DEFAULT now(),
                              updated_at timestamp with time zone DEFAULT now(),
                              CONSTRAINT users_pkey PRIMARY KEY (id)
);
CREATE TABLE public.verse_emotional_categories (
                                                   id integer NOT NULL DEFAULT nextval('verse_emotional_categories_id_seq'::regclass),
                                                   verse_id integer NOT NULL,
                                                   emotional_category_id integer NOT NULL,
                                                   created_at timestamp with time zone DEFAULT now(),
                                                   updated_at timestamp with time zone DEFAULT now(),
                                                   CONSTRAINT verse_emotional_categories_pkey PRIMARY KEY (id),
                                                   CONSTRAINT verse_emotional_categories_verse_id_fkey FOREIGN KEY (verse_id) REFERENCES public.verses(id),
                                                   CONSTRAINT verse_emotional_categories_emotional_category_id_fkey FOREIGN KEY (emotional_category_id) REFERENCES public.emotional_categories(id)
);
CREATE TABLE public.verses (
                               id integer NOT NULL DEFAULT nextval('verses_id_seq'::regclass),
                               book_id integer NOT NULL,
                               chapter_number integer NOT NULL,
                               verse_number integer NOT NULL,
                               text text NOT NULL,
                               keywords character varying,
                               created_at timestamp with time zone DEFAULT now(),
                               updated_at timestamp with time zone DEFAULT now(),
                               CONSTRAINT verses_pkey PRIMARY KEY (id),
                               CONSTRAINT verses_book_id_fkey FOREIGN KEY (book_id) REFERENCES public.books(id)
);
CREATE TABLE public.weekly_challenges (
                                          id integer NOT NULL DEFAULT nextval('weekly_challenges_id_seq'::regclass),
                                          title character varying NOT NULL,
                                          description text NOT NULL,
                                          start_date date NOT NULL,
                                          end_date date NOT NULL,
                                          challenge_type character varying NOT NULL,
                                          target_value integer NOT NULL,
                                          xp_reward integer NOT NULL DEFAULT 0,
                                          coin_reward integer NOT NULL DEFAULT 0,
                                          is_active boolean DEFAULT true,
                                          created_at timestamp with time zone DEFAULT now(),
                                          updated_at timestamp with time zone DEFAULT now(),
                                          CONSTRAINT weekly_challenges_pkey PRIMARY KEY (id)
);
CREATE TABLE public.weekly_progress (
                                        id integer NOT NULL DEFAULT nextval('weekly_progress_id_seq'::regclass),
                                        week_start_date date NOT NULL,
                                        devotionals_read_this_week integer NOT NULL DEFAULT 0,
                                        created_at timestamp with time zone DEFAULT now(),
                                        updated_at timestamp with time zone DEFAULT now(),
                                        user_profile_id uuid,
                                        CONSTRAINT weekly_progress_pkey PRIMARY KEY (id),
                                        CONSTRAINT weekly_progress_user_profile_id_fkey FOREIGN KEY (user_profile_id) REFERENCES public.user_profiles(id)
);
CREATE TABLE public.xp_config (
                                  action_name text NOT NULL,
                                  xp_amount integer NOT NULL,
                                  description text,
                                  created_at timestamp with time zone NOT NULL DEFAULT now(),
                                  updated_at timestamp with time zone NOT NULL DEFAULT now(),
                                  CONSTRAINT xp_config_pkey PRIMARY KEY (action_name)
);
CREATE TABLE public.xp_transactions (
                                        id integer NOT NULL DEFAULT nextval('xp_transactions_id_seq'::regclass),
                                        xp_amount integer NOT NULL,
                                        transaction_type character varying NOT NULL,
                                        created_at timestamp with time zone DEFAULT now(),
                                        updated_at timestamp with time zone DEFAULT now(),
                                        user_id uuid NOT NULL DEFAULT auth.uid(),
                                        description text,
                                        related_id integer,
                                        CONSTRAINT xp_transactions_pkey PRIMARY KEY (id),
                                        CONSTRAINT xp_transactions_user_profile_id_fkey FOREIGN KEY (user_id) REFERENCES public.user_profiles(id)
);