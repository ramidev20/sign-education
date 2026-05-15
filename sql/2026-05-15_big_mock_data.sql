-- EduBridge: Big Arabic mock dataset with French profile names.
--
-- IMPORTANT:
-- This assumes you already created these users in Supabase Auth.
-- `public.users.id` typically has a FK to `auth.users.id`, so we only UPSERT
-- profile rows here using the Auth UUIDs.
--
-- Source: UUIDs copied from your Supabase Auth users screenshots (May 15, 2026).
-- Re-runnable: uses fixed IDs + ON CONFLICT upserts where possible.

begin;

-- =========================
-- Users (profile rows)
-- =========================
-- Only insert rows whose UUID exists in Supabase Auth (prevents FK failures).
with desired_users (
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
  created_at
) as (
  values
  -- Teachers
  (
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    'teacher.arabic@edubridge.test',
    'Myriam Benyoussef',
    'teacher',
    null,
    null,
    null,
    null,
    array['arabic', 'islamic']::text[],
    '#781226',
    now() - interval '14 days'
  ),
  (
    'c7a64f12-2130-4f58-ad74-c7c40d794494',
    'teacher.karim@edubridge.test',
    'Karim Bensalem',
    'teacher',
    null,
    null,
    null,
    null,
    array['math', 'physics']::text[],
    '#0EA5E9',
    now() - interval '13 days'
  ),
  (
    '24705e86-2f67-404a-85ad-2bcfbede4fde',
    'teacher.nadia@edubridge.test',
    'Nadia Cherif',
    'teacher',
    null,
    null,
    null,
    null,
    array['languages', 'french', 'english']::text[],
    '#22C55E',
    now() - interval '13 days'
  ),
  (
    '89dd9b4f-8840-4860-b660-0a61f04fca03',
    'teacher.samia@edubridge.test',
    'Samia Rahmani',
    'teacher',
    null,
    null,
    null,
    null,
    array['natural_sciences', 'biology', 'chemistry']::text[],
    '#F59E0B',
    now() - interval '13 days'
  ),

  -- Students
  (
    '0d9875ab-94ff-4a3c-b88b-40a9936ece3e',
    'student.amine@edubridge.test',
    'Amine Slimani',
    'student',
    '4AM',
    'A',
    210,
    'mock_4am_a_arabic',
    null,
    '#C99A34',
    now() - interval '12 days'
  ),
  (
    '0f53fe9b-ea28-490b-bef2-532cb8c4e607',
    'student.sara@edubridge.test',
    'Sara Kadri',
    'student',
    '4AM',
    'A',
    160,
    'mock_4am_a_arabic',
    null,
    '#0EA5E9',
    now() - interval '12 days'
  ),
  (
    'a117f8b9-b5dc-414c-8590-5636ea9b928e',
    'student.yacine@edubridge.test',
    'Yacine Mourad',
    'student',
    '4AM',
    'A',
    130,
    'mock_4am_a_arabic',
    null,
    '#22C55E',
    now() - interval '12 days'
  ),
  (
    'd6c96c5c-7304-4c06-9f14-0359093a47bc',
    'student.sara2@edubridge.test',
    'Sara Benali',
    'student',
    '4AM',
    'A',
    95,
    'mock_4am_a_arabic',
    null,
    '#8B5CF6',
    now() - interval '11 days'
  ),
  (
    '370017d7-b9c6-4f1e-8b87-996637389a0a',
    'student.amine2@edubridge.test',
    'Amine Ait Ali',
    'student',
    '4AM',
    'A',
    80,
    'mock_4am_a_arabic',
    null,
    '#06B6D4',
    now() - interval '11 days'
  ),
  (
    '0b9893e5-4aa6-4777-b864-f03b2e058240',
    'student.lina@edubridge.test',
    'Lina Bouzid',
    'student',
    '4AM',
    'B',
    70,
    'mock_4am_b_math',
    null,
    '#EF4444',
    now() - interval '11 days'
  ),
  (
    'e3181327-e346-4c53-98e3-5374391b05cb',
    'student.mohamed@edubridge.test',
    'Mohamed Azzouzi',
    'student',
    '4AM',
    'B',
    60,
    'mock_4am_b_math',
    null,
    '#F97316',
    now() - interval '11 days'
  ),
  (
    '526d6a46-6ef9-4e55-b878-74f6edfe566f',
    'student.ikram@edubridge.test',
    'Ikram Boudiaf',
    'student',
    '3AM',
    'C',
    115,
    'mock_3am_c_lang',
    null,
    '#14B8A6',
    now() - interval '10 days'
  ),
  (
    '06eda833-241f-400b-8537-e22bd9c2e9c4',
    'student.ilyes@edubridge.test',
    'Ilyes Saidi',
    'student',
    '3AM',
    'C',
    140,
    'mock_3am_c_lang',
    null,
    '#A855F7',
    now() - interval '10 days'
  ),
  (
    '5a7c201e-2932-4ab8-a06e-699148ac22d1',
    'student.rania@edubridge.test',
    'Rania Messaoudi',
    'student',
    '3AM',
    'C',
    105,
    'mock_3am_c_lang',
    null,
    '#64748B',
    now() - interval '10 days'
  ),
  (
    '48d538be-6c9a-432f-a819-8f2ea9cbc9c1',
    'student.salima@edubridge.test',
    'Salima Hamdi',
    'student',
    '3AM',
    'C',
    90,
    'mock_3am_c_lang',
    null,
    '#0EA5E9',
    now() - interval '10 days'
  ),
  (
    'fe80f864-5c17-4671-9c58-b4d724a74f80',
    'student.hichem@edubridge.test',
    'Hichem Khelifi',
    'student',
    '3AM',
    'C',
    55,
    'mock_3am_c_lang',
    null,
    '#22C55E',
    now() - interval '10 days'
  ),
  (
    'baf2200a-28ba-46ef-b68d-3fbb56ae0526',
    'student.anas@edubridge.test',
    'Anas Zerrouki',
    'student',
    '4AM',
    'B',
    40,
    'mock_4am_b_math',
    null,
    '#F59E0B',
    now() - interval '11 days'
  ),
  (
    'd4a8a738-c50f-4340-b850-c3b1d662fd7d',
    'student.adel@edubridge.test',
    'Adel Touati',
    'student',
    '4AM',
    'B',
    65,
    'mock_4am_b_math',
    null,
    '#8B5CF6',
    now() - interval '11 days'
  ),
  (
    '81118816-9673-461e-823b-8771b7ac276e',
    'student.yasmine@edubridge.test',
    'Yasmine Belaid',
    'student',
    '4AM',
    'A',
    88,
    'mock_4am_a_arabic',
    null,
    '#06B6D4',
    now() - interval '11 days'
  )
)
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
)
select
  du.id::uuid,
  du.email,
  du.name,
  du.role,
  du.level,
  du.branch,
  du.points,
  du.class_group,
  du.subjects,
  du.avatar_color,
  du.created_at,
  now()
from desired_users du
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
-- Groups + members
-- =========================
with desired_groups (
  class_group_id,
  level,
  branch,
  subject,
  teacher_id,
  created_at,
  avatar_color,
  name
) as (
  values
    (
      'mock_4am_a_arabic',
      '4AM',
      'A',
      'اللغة العربية',
      '9ef3d541-f264-4181-a2bd-62f90751e1a4',
      now() - interval '12 days',
      '#781226',
      '4AM A - Arabe'
    ),
    (
      'mock_4am_b_math',
      '4AM',
      'B',
      'رياضيات',
      'c7a64f12-2130-4f58-ad74-c7c40d794494',
      now() - interval '11 days',
      '#0EA5E9',
      '4AM B - Math'
    ),
    (
      'mock_3am_c_lang',
      '3AM',
      'C',
      'اللغة الفرنسية',
      '24705e86-2f67-404a-85ad-2bcfbede4fde',
      now() - interval '10 days',
      '#22C55E',
      '3AM C - Langues'
    )
)
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
)
select
  g.class_group_id,
  g.level,
  g.branch,
  g.subject,
  g.teacher_id::uuid,
  g.created_at,
  g.avatar_color,
  g.name,
  now()
from desired_groups g
on conflict (class_group_id) do update set
  level = excluded.level,
  branch = excluded.branch,
  subject = excluded.subject,
  teacher_id = excluded.teacher_id,
  avatar_color = excluded.avatar_color,
  name = excluded.name,
  updated_at = now();

-- deterministic member IDs
with desired_members (id, class_group_id, user_id, role, created_at) as (
  values
    ('a0a00000-0000-4000-8000-000000000001','mock_4am_a_arabic','9ef3d541-f264-4181-a2bd-62f90751e1a4','teacher',now() - interval '12 days'),
    ('a0a00000-0000-4000-8000-000000000002','mock_4am_a_arabic','0d9875ab-94ff-4a3c-b88b-40a9936ece3e','student',now() - interval '12 days'),
    ('a0a00000-0000-4000-8000-000000000003','mock_4am_a_arabic','0f53fe9b-ea28-490b-bef2-532cb8c4e607','student',now() - interval '12 days'),
    ('a0a00000-0000-4000-8000-000000000004','mock_4am_a_arabic','a117f8b9-b5dc-414c-8590-5636ea9b928e','student',now() - interval '12 days'),
    ('a0a00000-0000-4000-8000-000000000005','mock_4am_a_arabic','d6c96c5c-7304-4c06-9f14-0359093a47bc','student',now() - interval '11 days'),
    ('a0a00000-0000-4000-8000-000000000006','mock_4am_a_arabic','370017d7-b9c6-4f1e-8b87-996637389a0a','student',now() - interval '11 days'),
    ('a0a00000-0000-4000-8000-000000000007','mock_4am_a_arabic','81118816-9673-461e-823b-8771b7ac276e','student',now() - interval '11 days'),

    ('a0a00000-0000-4000-8000-000000000101','mock_4am_b_math','c7a64f12-2130-4f58-ad74-c7c40d794494','teacher',now() - interval '11 days'),
    ('a0a00000-0000-4000-8000-000000000102','mock_4am_b_math','0b9893e5-4aa6-4777-b864-f03b2e058240','student',now() - interval '11 days'),
    ('a0a00000-0000-4000-8000-000000000103','mock_4am_b_math','e3181327-e346-4c53-98e3-5374391b05cb','student',now() - interval '11 days'),
    ('a0a00000-0000-4000-8000-000000000104','mock_4am_b_math','baf2200a-28ba-46ef-b68d-3fbb56ae0526','student',now() - interval '11 days'),
    ('a0a00000-0000-4000-8000-000000000105','mock_4am_b_math','d4a8a738-c50f-4340-b850-c3b1d662fd7d','student',now() - interval '11 days')
)
insert into public.class_group_members (id, class_group_id, user_id, role, created_at)
select m.id::uuid, m.class_group_id, m.user_id::uuid, m.role, m.created_at
from desired_members m
join public.class_groups cg on cg.class_group_id = m.class_group_id
on conflict (class_group_id, user_id) do update set
  role = excluded.role;

-- =========================
-- Messages (Arabic chats)
-- =========================
insert into public.messages (message_id, sender_id, receiver_id, class_group_id, text, created_at) values
  ('b0b00000-0000-4000-8000-000000000001','9ef3d541-f264-4181-a2bd-62f90751e1a4',null,'mock_4am_a_arabic','صباح الخير. اليوم سنراجع الفكرة العامة والأفكار الأساسية.',now() - interval '3 days 4 hours'),
  ('b0b00000-0000-4000-8000-000000000002','0d9875ab-94ff-4a3c-b88b-40a9936ece3e',null,'mock_4am_a_arabic','صباح النور أستاذة، هل هناك واجب؟',now() - interval '3 days 3 hours 56 minutes'),
  ('b0b00000-0000-4000-8000-000000000003','9ef3d541-f264-4181-a2bd-62f90751e1a4',null,'mock_4am_a_arabic','نعم، سأرسل واجباً قصيراً مع أسئلة اختيار من متعدد.',now() - interval '3 days 3 hours 50 minutes'),
  ('b0b00000-0000-4000-8000-000000000004','0f53fe9b-ea28-490b-bef2-532cb8c4e607',null,'mock_4am_a_arabic','شكرا، هل يمكن توضيح الفرق بين الفكرة العامة والمغزى؟',now() - interval '2 days 8 hours'),
  ('b0b00000-0000-4000-8000-000000000005','9ef3d541-f264-4181-a2bd-62f90751e1a4',null,'mock_4am_a_arabic','الفكرة العامة تلخص الموضوع، والمغزى هو العبرة المستفادة.',now() - interval '2 days 7 hours 56 minutes'),

  ('b0b00000-0000-4000-8000-000000000101','c7a64f12-2130-4f58-ad74-c7c40d794494',null,'mock_4am_b_math','مساء الخير. تمرين اليوم حول المعادلات من الدرجة الأولى.',now() - interval '2 days 6 hours'),
  ('b0b00000-0000-4000-8000-000000000102','e3181327-e346-4c53-98e3-5374391b05cb',null,'mock_4am_b_math','أستاذ، هل نحل في الكراس أم على الورقة؟',now() - interval '2 days 5 hours 52 minutes'),
  ('b0b00000-0000-4000-8000-000000000103','c7a64f12-2130-4f58-ad74-c7c40d794494',null,'mock_4am_b_math','في الكراس مع كتابة خطوات الحل كاملة.',now() - interval '2 days 5 hours 48 minutes')
on conflict (message_id) do update set
  text = excluded.text,
  created_at = excluded.created_at;

-- =========================
-- Lessons + strategies (JSON)
-- =========================
insert into public.lessons (
  lesson_id, subject, strategy_type, teacher_id, class_group_id, title, description, created_at, updated_at
) values
  ('c0c00000-0000-4000-8000-000000000001','arabic','type_0','9ef3d541-f264-4181-a2bd-62f90751e1a4','mock_4am_a_arabic','تحليل نص: قيمة العلم','خريطة ذهنية لاستخراج عناصر النص.',now() - interval '8 days',now()),
  ('c0c00000-0000-4000-8000-000000000002','history_geography','type_5','9ef3d541-f264-4181-a2bd-62f90751e1a4','mock_4am_a_arabic','محطات من تاريخ الجزائر','خط زمني لأبرز المحطات.',now() - interval '7 days',now()),
  ('c0c00000-0000-4000-8000-000000000101','math','type_10','c7a64f12-2130-4f58-ad74-c7c40d794494','mock_4am_b_math','مقارنة: طرق حل المعادلة','مقارنة بين طريقتين للحل.',now() - interval '6 days',now())
on conflict (lesson_id) do update set
  subject = excluded.subject,
  strategy_type = excluded.strategy_type,
  teacher_id = excluded.teacher_id,
  class_group_id = excluded.class_group_id,
  title = excluded.title,
  description = excluded.description,
  updated_at = now();

insert into public.lesson_strategies (
  lesson_strategy_id, lesson_id, strategy_type, title, content_json, created_at, updated_at
) values
  (
    'd0d00000-0000-4000-8000-000000000001',
    'c0c00000-0000-4000-8000-000000000001',
    'type_0',
    'خريطة ذهنية: قيمة العلم',
    '{
      "id": "root",
      "content": "قيمة العلم",
      "nodes": [
        {"id":"idea","content":"الفكرة العامة","nodes":[{"id":"idea-1","content":"العلم طريق التقدم وبناء المجتمع","nodes":[]}]},
        {"id":"values","content":"القيم","nodes":[{"id":"v1","content":"الاجتهاد","nodes":[]},{"id":"v2","content":"المثابرة","nodes":[]},{"id":"v3","content":"حب المعرفة","nodes":[]}]},
        {"id":"evidence","content":"شواهد","nodes":[{"id":"e1","content":"دعوة الكاتب إلى طلب العلم","nodes":[]},{"id":"e2","content":"ربط العلم بالنهضة","nodes":[]}]}
      ]
    }'::jsonb,
    now() - interval '8 days',
    now()
  ),
  (
    'd0d00000-0000-4000-8000-000000000002',
    'c0c00000-0000-4000-8000-000000000002',
    'type_5',
    'خط زمني: محطات من تاريخ الجزائر',
    '{
      "content":"محطات من تاريخ الجزائر",
      "nodes":[
        {"id":"t1","date":"1830-07-05","content":"بداية الاحتلال الفرنسي","nodes":[]},
        {"id":"t2","date":"1954-11-01","content":"اندلاع الثورة التحريرية","nodes":[]},
        {"id":"t3","date":"1962-07-05","content":"الاستقلال واسترجاع السيادة","nodes":[]}
      ]
    }'::jsonb,
    now() - interval '7 days',
    now()
  ),
  (
    'd0d00000-0000-4000-8000-000000000101',
    'c0c00000-0000-4000-8000-000000000101',
    'type_10',
    'مقارنة: طرق حل المعادلة',
    '{
      "title":"طرق حل المعادلة",
      "comparisonTable":[
        {"الخطوة الأولى":{"النقل":"نقل الحد إلى الطرف الآخر","التبسيط":"تبسيط الطرفين أولا"}},
        {"النتيجة":{"النقل":"تقليل الأخطاء عند التنظيم","التبسيط":"يُظهر الشكل النهائي بسرعة"}}
      ]
    }'::jsonb,
    now() - interval '6 days',
    now()
  )
on conflict (lesson_strategy_id) do update set
  lesson_id = excluded.lesson_id,
  strategy_type = excluded.strategy_type,
  title = excluded.title,
  content_json = excluded.content_json,
  updated_at = now();

-- =========================
-- Assignments + shares + deliveries (JSON)
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
  (
    'e0e00000-0000-4000-8000-000000000001',
    'arabic',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    'mock_4am_a_arabic',
    'واجب: الفكرة العامة والمغزى',
    'أجب عن الأسئلة ثم اكتب فقرة قصيرة.',
    'active',
    null,
    now() - interval '3 days',
    now() + interval '5 days',
    3,
    now(),
    '{
      "questions":[
        {"id":"q1","type":"mcq","prompt":"ما الفكرة العامة للنص؟","options":["أهمية العلم","وصف رحلة","قواعد الإملاء"]},
        {"id":"q2","type":"true_false","prompt":"المغزى هو العبرة المستفادة من النص."},
        {"id":"q3","type":"paragraph","prompt":"اكتب فقرة حول أهمية العلم في حياتك."}
      ]
    }'::jsonb
  ),
  (
    'e0e00000-0000-4000-8000-000000000101',
    'math',
    'c7a64f12-2130-4f58-ad74-c7c40d794494',
    'mock_4am_b_math',
    'واجب: المعادلات من الدرجة الأولى',
    'حل 6 معادلات مع شرح خطوات الحل.',
    'active',
    null,
    now() - interval '2 days',
    now() + interval '6 days',
    2,
    now(),
    '{
      "questions":[
        {"id":"m1","type":"number","prompt":"احسب قيمة x في: 3x + 2 = 11","allow_decimal":false,"min":-100,"max":100},
        {"id":"m2","type":"short_text","prompt":"اشرح خطوة نقل الحدود باختصار."},
        {"id":"m3","type":"mcq","prompt":"أي معادلة تمثل حالة توازن؟","options":["2x=4","x+1=0","5-x=3"]}
      ]
    }'::jsonb
  ),
  (
    'e0e00000-0000-4000-8000-000000000201',
    'french',
    '24705e86-2f67-404a-85ad-2bcfbede4fde',
    'mock_3am_c_lang',
    'واجب: التعبير الكتابي',
    'اكتب فقرة منظمة حول التعاون.',
    'active',
    null,
    now() - interval '1 day',
    now() + interval '7 days',
    1,
    now(),
    '{
      "questions":[
        {"id":"f1","type":"paragraph","prompt":"اكتب فقرة من 6 أسطر حول التعاون وأثره في المجتمع."}
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
  submissions_count = excluded.submissions_count,
  assignment_content_json = excluded.assignment_content_json,
  updated_at = now();

-- shares
insert into public.assignment_shares (id, assignment_id, user_id, created_at, updated_at) values
  ('f0f00000-0000-4000-8000-000000000001','e0e00000-0000-4000-8000-000000000001','0d9875ab-94ff-4a3c-b88b-40a9936ece3e',now() - interval '3 days',now()),
  ('f0f00000-0000-4000-8000-000000000002','e0e00000-0000-4000-8000-000000000001','0f53fe9b-ea28-490b-bef2-532cb8c4e607',now() - interval '3 days',now()),
  ('f0f00000-0000-4000-8000-000000000003','e0e00000-0000-4000-8000-000000000001','a117f8b9-b5dc-414c-8590-5636ea9b928e',now() - interval '3 days',now()),
  ('f0f00000-0000-4000-8000-000000000004','e0e00000-0000-4000-8000-000000000001','d6c96c5c-7304-4c06-9f14-0359093a47bc',now() - interval '3 days',now()),
  ('f0f00000-0000-4000-8000-000000000101','e0e00000-0000-4000-8000-000000000101','0b9893e5-4aa6-4777-b864-f03b2e058240',now() - interval '2 days',now()),
  ('f0f00000-0000-4000-8000-000000000102','e0e00000-0000-4000-8000-000000000101','e3181327-e346-4c53-98e3-5374391b05cb',now() - interval '2 days',now()),
  ('f0f00000-0000-4000-8000-000000000103','e0e00000-0000-4000-8000-000000000101','baf2200a-28ba-46ef-b68d-3fbb56ae0526',now() - interval '2 days',now()),
  ('f0f00000-0000-4000-8000-000000000104','e0e00000-0000-4000-8000-000000000101','d4a8a738-c50f-4340-b850-c3b1d662fd7d',now() - interval '2 days',now()),
  ('f0f00000-0000-4000-8000-000000000201','e0e00000-0000-4000-8000-000000000201','526d6a46-6ef9-4e55-b878-74f6edfe566f',now() - interval '1 day',now()),
  ('f0f00000-0000-4000-8000-000000000202','e0e00000-0000-4000-8000-000000000201','06eda833-241f-400b-8537-e22bd9c2e9c4',now() - interval '1 day',now()),
  ('f0f00000-0000-4000-8000-000000000203','e0e00000-0000-4000-8000-000000000201','5a7c201e-2932-4ab8-a06e-699148ac22d1',now() - interval '1 day',now())
on conflict (assignment_id, user_id) do update set
  updated_at = now();

-- deliveries (must be unique per assignment_id,user_id)
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
    '90000000-0000-4000-8000-000000000001',
    'e0e00000-0000-4000-8000-000000000001',
    '0d9875ab-94ff-4a3c-b88b-40a9936ece3e',
    'Amine Slimani',
    '',
    now() - interval '18 hours',
    'reviewed',
    'Bon travail. Essaie d''enrichir la conclusion.',
    now() - interval '18 hours',
    now(),
    '{
      "answers":[
        {"question_id":"q1","type":"mcq","value":"أهمية العلم"},
        {"question_id":"q2","type":"true_false","value":true},
        {"question_id":"q3","type":"paragraph","value":"العلم نور يرفع من شأن الإنسان ويساعده على فهم العالم واتخاذ قرارات صحيحة."}
      ]
    }'::jsonb
  ),
  (
    '90000000-0000-4000-8000-000000000002',
    'e0e00000-0000-4000-8000-000000000001',
    '0f53fe9b-ea28-490b-bef2-532cb8c4e607',
    'Sara Kadri',
    '',
    now() - interval '12 hours',
    'pending',
    null,
    now() - interval '12 hours',
    now(),
    '{
      "answers":[
        {"question_id":"q1","type":"mcq","value":"أهمية العلم"},
        {"question_id":"q2","type":"true_false","value":true},
        {"question_id":"q3","type":"paragraph","value":"العلم يساعدنا على التقدم في الدراسة ويجعلنا نفهم الدروس بسهولة ونخدم مجتمعنا."}
      ]
    }'::jsonb
  ),
  (
    '90000000-0000-4000-8000-000000000101',
    'e0e00000-0000-4000-8000-000000000101',
    '0b9893e5-4aa6-4777-b864-f03b2e058240',
    'Lina Bouzid',
    '',
    now() - interval '10 hours',
    'approved',
    null,
    now() - interval '10 hours',
    now(),
    '{
      "answers":[
        {"question_id":"m1","type":"number","value":3},
        {"question_id":"m2","type":"short_text","value":"ننقل الحد إلى الطرف الآخر مع تغيير الإشارة ثم نبسط."},
        {"question_id":"m3","type":"mcq","value":"2x=4"}
      ]
    }'::jsonb
  ),
  (
    '90000000-0000-4000-8000-000000000201',
    'e0e00000-0000-4000-8000-000000000201',
    '526d6a46-6ef9-4e55-b878-74f6edfe566f',
    'Ikram Boudiaf',
    '',
    now() - interval '6 hours',
    'rejected',
    'Merci. Ajoute des connecteurs logiques et une conclusion plus claire.',
    now() - interval '6 hours',
    now(),
    '{
      "answers":[
        {"question_id":"f1","type":"paragraph","value":"التعاون يجعل العمل أسهل ويقوي العلاقات بين الناس. يساعد على تحقيق الأهداف بسرعة ويحسن روح الفريق."}
      ]
    }'::jsonb
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
