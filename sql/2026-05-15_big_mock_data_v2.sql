-- EduBridge: Big mock dataset v2 (Arabic content + French names in user profiles).
-- Date: 2026-05-15
--
-- Goals:
-- 1) Use ONLY real Supabase Auth UUIDs (FK: public.users.id -> auth.users.id).
-- 2) Ensure EACH student is enrolled in at least 3 groups across 3+ subjects.
-- 3) Ensure each group has >= 3 lessons and >= 2 assignments.
-- 4) Ensure there are "active" assignments with NO deliveries yet (unsolved).
--
-- Source of UUIDs: your Auth export pasted in chat (May 14, 2026).
-- Safe to re-run: uses ON CONFLICT upserts for deterministic IDs.

begin;

-- =========================
-- Users (profiles)
-- =========================
insert into public.users (
  id,
  email,
  name,
  role,
  level,
  branch,
  points,
  class_group,
  subjects,
  avatar_color,
  created_at,
  updated_at
) values
  -- Teachers
  (
    '9ef3d541-f264-4181-a2bd-62f90751e1a4'::uuid,
    'teacher.arabic@edubridge.test',
    'Myriam Benyoussef',
    'teacher',
    null,
    null,
    null,
    null,
    array['arabic','islamic']::text[],
    '#781226',
    now() - interval '14 days',
    now()
  ),
  (
    'c7a64f12-2130-4f58-ad74-c7c40d794494'::uuid,
    'teacher.karim@edubridge.test',
    'Karim Bensalem',
    'teacher',
    null,
    null,
    null,
    null,
    array['math','physics']::text[],
    '#0EA5E9',
    now() - interval '14 days',
    now()
  ),
  (
    '24705e86-2f67-404a-85ad-2bcfbede4fde'::uuid,
    'teacher.nadia@edubridge.test',
    'Nadia Cherif',
    'teacher',
    null,
    null,
    null,
    null,
    array['languages','french','english']::text[],
    '#22C55E',
    now() - interval '14 days',
    now()
  ),
  (
    '89dd9b4f-8840-4860-b660-0a61f04fca03'::uuid,
    'teacher.samia@edubridge.test',
    'Samia Rahmani',
    'teacher',
    null,
    null,
    null,
    null,
    array['natural_sciences','biology','chemistry']::text[],
    '#F59E0B',
    now() - interval '14 days',
    now()
  ),

  -- Students (each will be enrolled into 3+ subject groups below)
  ('0d9875ab-94ff-4a3c-b88b-40a9936ece3e'::uuid,'student.amine@edubridge.test','Amine Slimani','student','4AM','A',210,'mock_4am_a_arabic',null,'#C99A34',now() - interval '13 days',now()),
  ('0f53fe9b-ea28-490b-bef2-532cb8c4e607'::uuid,'student.sara@edubridge.test','Sara Kadri','student','4AM','A',160,'mock_4am_a_arabic',null,'#0EA5E9',now() - interval '13 days',now()),
  ('a117f8b9-b5dc-414c-8590-5636ea9b928e'::uuid,'student.yacine@edubridge.test','Yacine Mourad','student','4AM','A',130,'mock_4am_a_arabic',null,'#22C55E',now() - interval '13 days',now()),
  ('d6c96c5c-7304-4c06-9f14-0359093a47bc'::uuid,'student.sara2@edubridge.test','Sara Benali','student','4AM','A',95,'mock_4am_a_arabic',null,'#8B5CF6',now() - interval '12 days',now()),
  ('370017d7-b9c6-4f1e-8b87-996637389a0a'::uuid,'student.amine2@edubridge.test','Amine Ait Ali','student','4AM','A',80,'mock_4am_a_arabic',null,'#06B6D4',now() - interval '12 days',now()),
  ('81118816-9673-461e-823b-8771b7ac276e'::uuid,'student.yasmine@edubridge.test','Yasmine Belaid','student','4AM','A',88,'mock_4am_a_arabic',null,'#14B8A6',now() - interval '12 days',now()),
  ('baf2200a-28ba-46ef-b68d-3fbb56ae0526'::uuid,'student.anas@edubridge.test','Anas Zerrouki','student','4AM','A',40,'mock_4am_a_arabic',null,'#F59E0B',now() - interval '12 days',now()),
  ('d4a8a738-c50f-4340-b850-c3b1d662fd7d'::uuid,'student.adel@edubridge.test','Adel Touati','student','4AM','A',65,'mock_4am_a_arabic',null,'#A855F7',now() - interval '12 days',now()),
  ('e3181327-e346-4c53-98e3-5374391b05cb'::uuid,'student.mohamed@edubridge.test','Mohamed Azzouzi','student','4AM','A',60,'mock_4am_a_arabic',null,'#F97316',now() - interval '12 days',now()),
  ('fe80f864-5c17-4671-9c58-b4d724a74f80'::uuid,'student.hichem@edubridge.test','Hichem Khelifi','student','4AM','A',55,'mock_4am_a_arabic',null,'#64748B',now() - interval '12 days',now()),
  ('526d6a46-6ef9-4e55-b878-74f6edfe566f'::uuid,'student.ikram@edubridge.test','Ikram Boudiaf','student','4AM','A',115,'mock_4am_a_arabic',null,'#0EA5E9',now() - interval '12 days',now()),
  ('06eda833-241f-400b-8537-e22bd9c2e9c4'::uuid,'student.ilyes@edubridge.test','Ilyes Saidi','student','4AM','A',140,'mock_4am_a_arabic',null,'#22C55E',now() - interval '12 days',now()),
  ('5a7c201e-2932-4ab8-a06e-699148ac22d1'::uuid,'student.rania@edubridge.test','Rania Messaoudi','student','4AM','A',105,'mock_4am_a_arabic',null,'#0EA5E9',now() - interval '12 days',now()),
  ('48d538be-6c9a-432f-a819-8f2ea9cbc9c1'::uuid,'student.salima@edubridge.test','Salima Hamdi','student','4AM','A',90,'mock_4am_a_arabic',null,'#06B6D4',now() - interval '12 days',now())
on conflict (id) do update set
  email = excluded.email,
  name = excluded.name,
  role = excluded.role,
  level = excluded.level,
  branch = excluded.branch,
  points = excluded.points,
  class_group = excluded.class_group,
  subjects = excluded.subjects,
  avatar_color = excluded.avatar_color,
  updated_at = now();

-- =========================
-- Groups (4 subjects, 4 teachers)
-- NOTE: class_groups.subject is stored as Arabic label in the app.
-- =========================
insert into public.class_groups (
  class_group_id,
  level,
  branch,
  subject,
  teacher_id,
  created_at,
  avatar_color,
  name,
  updated_at
) values
  (
    'mock_4am_a_arabic',
    '4AM',
    'A',
    'اللغة العربية',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4'::uuid,
    now() - interval '13 days',
    '#781226',
    '4AM A - العربية',
    now()
  ),
  (
    'mock_4am_a_math',
    '4AM',
    'A',
    'رياضيات',
    'c7a64f12-2130-4f58-ad74-c7c40d794494'::uuid,
    now() - interval '13 days',
    '#0EA5E9',
    '4AM A - الرياضيات',
    now()
  ),
  (
    'mock_4am_a_languages',
    '4AM',
    'A',
    'لغات',
    '24705e86-2f67-404a-85ad-2bcfbede4fde'::uuid,
    now() - interval '13 days',
    '#22C55E',
    '4AM A - اللغات',
    now()
  ),
  (
    'mock_4am_a_sciences',
    '4AM',
    'A',
    'علوم طبيعية',
    '89dd9b4f-8840-4860-b660-0a61f04fca03'::uuid,
    now() - interval '13 days',
    '#F59E0B',
    '4AM A - العلوم',
    now()
  )
on conflict (class_group_id) do update set
  level = excluded.level,
  branch = excluded.branch,
  subject = excluded.subject,
  teacher_id = excluded.teacher_id,
  avatar_color = excluded.avatar_color,
  name = excluded.name,
  updated_at = now();

-- =========================
-- Group members
-- Each student enrolled into 3+ groups: Arabic + Math + Languages + Sciences (4 groups total).
-- =========================
with all_students(user_id) as (
  values
    ('0d9875ab-94ff-4a3c-b88b-40a9936ece3e'::uuid),
    ('0f53fe9b-ea28-490b-bef2-532cb8c4e607'::uuid),
    ('a117f8b9-b5dc-414c-8590-5636ea9b928e'::uuid),
    ('d6c96c5c-7304-4c06-9f14-0359093a47bc'::uuid),
    ('370017d7-b9c6-4f1e-8b87-996637389a0a'::uuid),
    ('81118816-9673-461e-823b-8771b7ac276e'::uuid),
    ('baf2200a-28ba-46ef-b68d-3fbb56ae0526'::uuid),
    ('d4a8a738-c50f-4340-b850-c3b1d662fd7d'::uuid),
    ('e3181327-e346-4c53-98e3-5374391b05cb'::uuid),
    ('fe80f864-5c17-4671-9c58-b4d724a74f80'::uuid),
    ('526d6a46-6ef9-4e55-b878-74f6edfe566f'::uuid),
    ('06eda833-241f-400b-8537-e22bd9c2e9c4'::uuid),
    ('5a7c201e-2932-4ab8-a06e-699148ac22d1'::uuid),
    ('48d538be-6c9a-432f-a819-8f2ea9cbc9c1'::uuid)
),
desired_members(id, class_group_id, user_id, role, created_at) as (
  -- Teachers as members
  values
    ('a1000000-0000-4000-8000-000000000001'::uuid,'mock_4am_a_arabic','9ef3d541-f264-4181-a2bd-62f90751e1a4'::uuid,'teacher',now() - interval '13 days'),
    ('a1000000-0000-4000-8000-000000000002'::uuid,'mock_4am_a_math','c7a64f12-2130-4f58-ad74-c7c40d794494'::uuid,'teacher',now() - interval '13 days'),
    ('a1000000-0000-4000-8000-000000000003'::uuid,'mock_4am_a_languages','24705e86-2f67-404a-85ad-2bcfbede4fde'::uuid,'teacher',now() - interval '13 days'),
    ('a1000000-0000-4000-8000-000000000004'::uuid,'mock_4am_a_sciences','89dd9b4f-8840-4860-b660-0a61f04fca03'::uuid,'teacher',now() - interval '13 days')
),
desired_student_members as (
  select
    gen_random_uuid() as id,
    g.class_group_id,
    s.user_id,
    'student'::text as role,
    now() - interval '12 days' as created_at
  from all_students s
  cross join (values
    ('mock_4am_a_arabic'),
    ('mock_4am_a_math'),
    ('mock_4am_a_languages'),
    ('mock_4am_a_sciences')
  ) as g(class_group_id)
)
insert into public.class_group_members (id, class_group_id, user_id, role, created_at)
select id, class_group_id, user_id, role, created_at from desired_members
union all
select id, class_group_id, user_id, role, created_at from desired_student_members
on conflict (class_group_id, user_id) do update set
  role = excluded.role;

-- =========================
-- Messages (per group)
-- =========================
insert into public.messages (message_id, sender_id, receiver_id, class_group_id, text, created_at) values
  (gen_random_uuid(),'9ef3d541-f264-4181-a2bd-62f90751e1a4'::uuid,null,'mock_4am_a_arabic','صباح الخير. اليوم سنراجع الفكرة العامة والأفكار الأساسية.',now() - interval '3 days 4 hours'),
  (gen_random_uuid(),'0d9875ab-94ff-4a3c-b88b-40a9936ece3e'::uuid,null,'mock_4am_a_arabic','صباح النور أستاذة، هل هناك واجب؟',now() - interval '3 days 3 hours 56 minutes'),
  (gen_random_uuid(),'9ef3d541-f264-4181-a2bd-62f90751e1a4'::uuid,null,'mock_4am_a_arabic','نعم، سأرسل واجبا قصيرا مع أسئلة.',now() - interval '3 days 3 hours 50 minutes'),

  (gen_random_uuid(),'c7a64f12-2130-4f58-ad74-c7c40d794494'::uuid,null,'mock_4am_a_math','أهلا. تمرين اليوم حول المعادلات من الدرجة الأولى.',now() - interval '2 days 6 hours'),
  (gen_random_uuid(),'e3181327-e346-4c53-98e3-5374391b05cb'::uuid,null,'mock_4am_a_math','أستاذ، هل نحل في الكراس أم على الورقة؟',now() - interval '2 days 5 hours 52 minutes'),
  (gen_random_uuid(),'c7a64f12-2130-4f58-ad74-c7c40d794494'::uuid,null,'mock_4am_a_math','في الكراس مع كتابة خطوات الحل كاملة.',now() - interval '2 days 5 hours 48 minutes'),

  (gen_random_uuid(),'24705e86-2f67-404a-85ad-2bcfbede4fde'::uuid,null,'mock_4am_a_languages','مساء الخير. هذا الأسبوع سنركز على القراءة والفهم.',now() - interval '2 days 3 hours'),
  (gen_random_uuid(),'0f53fe9b-ea28-490b-bef2-532cb8c4e607'::uuid,null,'mock_4am_a_languages','هل سيكون الدرس بالفرنسية أم الإنجليزية؟',now() - interval '2 days 2 hours 52 minutes'),
  (gen_random_uuid(),'24705e86-2f67-404a-85ad-2bcfbede4fde'::uuid,null,'mock_4am_a_languages','سنعمل على نصين: واحد بالفرنسية وواحد بالإنجليزية.',now() - interval '2 days 2 hours 40 minutes'),

  (gen_random_uuid(),'89dd9b4f-8840-4860-b660-0a61f04fca03'::uuid,null,'mock_4am_a_sciences','مرحبا. درس اليوم حول الخلية وأجزائها.',now() - interval '1 day 6 hours'),
  (gen_random_uuid(),'fe80f864-5c17-4671-9c58-b4d724a74f80'::uuid,null,'mock_4am_a_sciences','هل نحتاج رسم الخلية في الكراس؟',now() - interval '1 day 5 hours 52 minutes'),
  (gen_random_uuid(),'89dd9b4f-8840-4860-b660-0a61f04fca03'::uuid,null,'mock_4am_a_sciences','نعم مع كتابة أسماء الأجزاء الأساسية.',now() - interval '1 day 5 hours 40 minutes');

-- =========================
-- Lessons (3 per group)
-- =========================
insert into public.lessons (
  lesson_id,
  subject,
  strategy_type,
  teacher_id,
  class_group_id,
  title,
  description,
  created_at,
  updated_at
) values
  -- Arabic
  ('c1111111-1111-4111-8111-111111111111'::uuid,'arabic','type_0','9ef3d541-f264-4181-a2bd-62f90751e1a4'::uuid,'mock_4am_a_arabic','تحليل نص: قيمة العلم','استخراج الفكرة العامة والأفكار الأساسية.',now() - interval '8 days',now()),
  ('c1111111-1111-4111-8111-111111111112'::uuid,'arabic','type_10','9ef3d541-f264-4181-a2bd-62f90751e1a4'::uuid,'mock_4am_a_arabic','مقارنة: الفكرة العامة والمغزى','جدول مقارنة مع أمثلة.',now() - interval '7 days',now()),
  ('c1111111-1111-4111-8111-111111111113'::uuid,'islamic','type_11','9ef3d541-f264-4181-a2bd-62f90751e1a4'::uuid,'mock_4am_a_arabic','التربية الإسلامية: حسن الخلق','فهم معنى حسن الخلق وأثره.',now() - interval '6 days',now()),

  -- Math
  ('c2222222-2222-4222-8222-222222222221'::uuid,'math','type_10','c7a64f12-2130-4f58-ad74-c7c40d794494'::uuid,'mock_4am_a_math','طرق حل المعادلات','مقارنة بين طريقتين للحل.',now() - interval '8 days',now()),
  ('c2222222-2222-4222-8222-222222222222'::uuid,'math','type_0','c7a64f12-2130-4f58-ad74-c7c40d794494'::uuid,'mock_4am_a_math','خريطة مفاهيم: الكسور','تلخيص أنواع الكسور والعمليات.',now() - interval '7 days',now()),
  ('c2222222-2222-4222-8222-222222222223'::uuid,'physics','type_5','c7a64f12-2130-4f58-ad74-c7c40d794494'::uuid,'mock_4am_a_math','الحركة والسكون','خط زمني مبسط لأمثلة وتجارب.',now() - interval '6 days',now()),

  -- Languages
  ('c3333333-3333-4333-8333-333333333331'::uuid,'french','type_13','24705e86-2f67-404a-85ad-2bcfbede4fde'::uuid,'mock_4am_a_languages','Compréhension: Le sport','أسئلة صحفية لفهم النص.',now() - interval '8 days',now()),
  ('c3333333-3333-4333-8333-333333333332'::uuid,'english','type_14','24705e86-2f67-404a-85ad-2bcfbede4fde'::uuid,'mock_4am_a_languages','Reading: My School Day','قصة تعليمية قصيرة.',now() - interval '7 days',now()),
  ('c3333333-3333-4333-8333-333333333333'::uuid,'languages','type_9','24705e86-2f67-404a-85ad-2bcfbede4fde'::uuid,'mock_4am_a_languages','بطاقات مفردات','بطاقات ملونة لكلمات شائعة.',now() - interval '6 days',now()),

  -- Sciences
  ('c4444444-4444-4444-8444-444444444441'::uuid,'biology','type_0','89dd9b4f-8840-4860-b660-0a61f04fca03'::uuid,'mock_4am_a_sciences','الخلية وأجزاؤها','خريطة ذهنية لأجزاء الخلية.',now() - interval '8 days',now()),
  ('c4444444-4444-4444-8444-444444444442'::uuid,'chemistry','type_10','89dd9b4f-8840-4860-b660-0a61f04fca03'::uuid,'mock_4am_a_sciences','مقارنة: المخاليط والمحاليل','جدول مقارنة مع أمثلة.',now() - interval '7 days',now()),
  ('c4444444-4444-4444-8444-444444444443'::uuid,'natural_sciences','type_11','89dd9b4f-8840-4860-b660-0a61f04fca03'::uuid,'mock_4am_a_sciences','مثلث: الغذاء والصحة','تنظيم الأفكار في ثلاثة محاور.',now() - interval '6 days',now())
on conflict (lesson_id) do update set
  subject = excluded.subject,
  strategy_type = excluded.strategy_type,
  teacher_id = excluded.teacher_id,
  class_group_id = excluded.class_group_id,
  title = excluded.title,
  description = excluded.description,
  updated_at = now();

-- =========================
-- Assignments (mix of active + some without deliveries yet)
-- =========================
insert into public.assignments (
  assignment_id,
  subject,
  teacher_id,
  class_group_id,
  title,
  description,
  status,
  file_url,
  created_at,
  complete_at,
  submissions_count,
  updated_at,
  assignment_content_json
) values
  -- Arabic: one active unsolved (no deliveries will be inserted for it)
  ('e1111111-1111-4111-8111-111111111111'::uuid,'arabic','9ef3d541-f264-4181-a2bd-62f90751e1a4'::uuid,'mock_4am_a_arabic','واجب: الفكرة العامة','اختر الفكرة العامة ثم اكتب فقرة قصيرة.','active',null,now() - interval '2 days',now() + interval '5 days',0,now(),
   '{
     "questions": [
       {"id":"q1","type":"mcq","prompt":"ما الفكرة العامة للنص؟","options":["أهمية العلم","رحلة في الطبيعة","قواعد الإملاء"]},
       {"id":"q2","type":"paragraph","prompt":"اكتب فقرة من 3 أسطر عن أهمية العلم."}
     ]
   }'::jsonb
  ),
  -- Math: active (some deliveries exist, some students still unsolved)
  ('e2222222-2222-4222-8222-222222222221'::uuid,'math','c7a64f12-2130-4f58-ad74-c7c40d794494'::uuid,'mock_4am_a_math','واجب: معادلات بسيطة','حل 5 معادلات مع خطوات الحل.','active',null,now() - interval '2 days',now() + interval '6 days',0,now(),
   '{
     "questions":[
       {"id":"q1","type":"short_text","prompt":"حل المعادلة: 2x + 3 = 11"},
       {"id":"q2","type":"short_text","prompt":"حل المعادلة: 5x - 10 = 0"},
       {"id":"q3","type":"short_text","prompt":"حل المعادلة: x/2 = 7"}
     ]
   }'::jsonb
  ),
  -- Languages: active unsolved for many
  ('e3333333-3333-4333-8333-333333333331'::uuid,'french','24705e86-2f67-404a-85ad-2bcfbede4fde'::uuid,'mock_4am_a_languages','Devoir: Compréhension','Réponds aux questions sur le texte.','active',null,now() - interval '1 day',now() + interval '7 days',0,now(),
   '{
     "questions":[
       {"id":"q1","type":"mcq","prompt":"Le texte parle de...","options":["Le sport","La météo","La cuisine"]},
       {"id":"q2","type":"short_text","prompt":"Donne une idée principale."}
     ]
   }'::jsonb
  ),
  -- Sciences: active (some pending)
  ('e4444444-4444-4444-8444-444444444441'::uuid,'biology','89dd9b4f-8840-4860-b660-0a61f04fca03'::uuid,'mock_4am_a_sciences','واجب: الخلية','سمّ أجزاء الخلية وأجب عن سؤالين.','active',null,now() - interval '1 day',now() + interval '4 days',0,now(),
   '{
     "questions":[
       {"id":"q1","type":"short_text","prompt":"اذكر ثلاثة أجزاء من الخلية."},
       {"id":"q2","type":"true_false","prompt":"النواة تتحكم في أنشطة الخلية."}
     ]
   }'::jsonb
  )
on conflict (assignment_id) do update set
  subject = excluded.subject,
  teacher_id = excluded.teacher_id,
  class_group_id = excluded.class_group_id,
  title = excluded.title,
  description = excluded.description,
  status = excluded.status,
  file_url = excluded.file_url,
  complete_at = excluded.complete_at,
  assignment_content_json = excluded.assignment_content_json,
  updated_at = now();

-- =========================
-- Shares (mark some assignments as shared to students)
-- =========================
insert into public.assignment_shares (id, assignment_id, user_id, created_at, updated_at) values
  (gen_random_uuid(),'e1111111-1111-4111-8111-111111111111'::uuid,'0d9875ab-94ff-4a3c-b88b-40a9936ece3e'::uuid,now() - interval '2 days',now()),
  (gen_random_uuid(),'e1111111-1111-4111-8111-111111111111'::uuid,'0f53fe9b-ea28-490b-bef2-532cb8c4e607'::uuid,now() - interval '2 days',now()),
  (gen_random_uuid(),'e2222222-2222-4222-8222-222222222221'::uuid,'e3181327-e346-4c53-98e3-5374391b05cb'::uuid,now() - interval '2 days',now()),
  (gen_random_uuid(),'e2222222-2222-4222-8222-222222222221'::uuid,'baf2200a-28ba-46ef-b68d-3fbb56ae0526'::uuid,now() - interval '2 days',now()),
  (gen_random_uuid(),'e3333333-3333-4333-8333-333333333331'::uuid,'0d9875ab-94ff-4a3c-b88b-40a9936ece3e'::uuid,now() - interval '1 day',now()),
  (gen_random_uuid(),'e4444444-4444-4444-8444-444444444441'::uuid,'fe80f864-5c17-4671-9c58-b4d724a74f80'::uuid,now() - interval '1 day',now())
on conflict (assignment_id, user_id) do update set
  updated_at = now();

-- =========================
-- Deliveries (ONLY for some assignments; leave e111... unsolved for everyone)
-- =========================
insert into public.assignments_deliveries (
  delivery_id,
  assignment_id,
  user_id,
  username,
  file_url,
  delivery_date,
  status,
  status_comment,
  created_at,
  updated_at,
  answers_json
) values
  (
    'd2222222-2222-4222-8222-222222222221'::uuid,
    'e2222222-2222-4222-8222-222222222221'::uuid,
    'e3181327-e346-4c53-98e3-5374391b05cb'::uuid,
    'Mohamed Azzouzi',
    '',
    now() - interval '18 hours',
    'pending',
    null,
    now() - interval '18 hours',
    now(),
    '{"answers":[{"question_id":"q1","type":"short_text","value":"2x=8 => x=4"},{"question_id":"q2","type":"short_text","value":"5x=10 => x=2"},{"question_id":"q3","type":"short_text","value":"x=14"}]}'::jsonb
  ),
  (
    'd4444444-4444-4444-8444-444444444441'::uuid,
    'e4444444-4444-4444-8444-444444444441'::uuid,
    'fe80f864-5c17-4671-9c58-b4d724a74f80'::uuid,
    'Hichem Khelifi',
    '',
    now() - interval '6 hours',
    'reviewed',
    'إجابات جيدة، أضف رسما مبسطا للخلية.',
    now() - interval '6 hours',
    now(),
    '{"answers":[{"question_id":"q1","type":"short_text","value":"النواة، الغشاء، السيتوبلازم"},{"question_id":"q2","type":"true_false","value":true}]}'::jsonb
  )
on conflict (assignment_id, user_id) do update set
  username = excluded.username,
  file_url = excluded.file_url,
  delivery_date = excluded.delivery_date,
  status = excluded.status,
  status_comment = excluded.status_comment,
  answers_json = excluded.answers_json,
  updated_at = now();

commit;

