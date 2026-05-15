-- EduBridge Arabic mock data.
-- Safe to run more than once: rows use fixed IDs and ON CONFLICT upserts.

begin;

-- NOTE:
-- This project typically has a FK from `public.users.id` -> `auth.users.id`.
-- So you must create Auth users first (Supabase Auth), then upsert their
-- profile rows in `public.users` using the *same* UUIDs.
--
-- These UUIDs were taken from your Supabase Auth "Users" list screenshot.
-- If they differ in your project, replace them below.

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
  (
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    'teacher.arabic@edubridge.test',
    'الأستاذة مريم بن يوسف',
    'teacher',
    null,
    null,
    null,
    null,
    array['arabic', 'islamic']::text[],
    '#781226',
    now() - interval '10 days',
    now()
  ),
  (
    '0d9875ab-94ff-4a3c-b88b-40a9936ece3e',
    'student.amine@edubridge.test',
    'أمين سليماني',
    'student',
    'السنة الرابعة متوسط',
    'قسم أ',
    180,
    'mock_4am_a_arabic',
    null,
    '#C99A34',
    now() - interval '9 days',
    now()
  ),
  (
    '0f53fe9b-ea28-490b-bef2-532cb8c4e607',
    'student.sara@edubridge.test',
    'سارة قادري',
    'student',
    'السنة الرابعة متوسط',
    'قسم أ',
    145,
    'mock_4am_a_arabic',
    null,
    '#0EA5E9',
    now() - interval '9 days',
    now()
  ),
  (
    'a117f8b9-b5dc-414c-8590-5636ea9b928e',
    'student.yacine@edubridge.test',
    'ياسين مراد',
    'student',
    'السنة الرابعة متوسط',
    'قسم أ',
    120,
    'mock_4am_a_arabic',
    null,
    '#22C55E',
    now() - interval '8 days',
    now()
  )
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

insert into public.class_groups (
  class_group_id,
  level,
  branch,
  subject,
  teacher_id,
  avatar_color,
  name,
  created_at,
  updated_at
) values (
  'mock_4am_a_arabic',
  'السنة الرابعة متوسط',
  'قسم أ',
  'اللغة العربية',
  '9ef3d541-f264-4181-a2bd-62f90751e1a4',
  '#781226',
  'قسم العربية - الرابعة متوسط أ',
  now() - interval '8 days',
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

insert into public.class_group_members (
  id,
  class_group_id,
  user_id,
  role,
  created_at
) values
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
    'mock_4am_a_arabic',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    'teacher',
    now() - interval '8 days'
  ),
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2',
    'mock_4am_a_arabic',
    '0d9875ab-94ff-4a3c-b88b-40a9936ece3e',
    'student',
    now() - interval '8 days'
  ),
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3',
    'mock_4am_a_arabic',
    '0f53fe9b-ea28-490b-bef2-532cb8c4e607',
    'student',
    now() - interval '8 days'
  ),
  (
    'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4',
    'mock_4am_a_arabic',
    'a117f8b9-b5dc-414c-8590-5636ea9b928e',
    'student',
    now() - interval '8 days'
  )
on conflict (class_group_id, user_id) do update set
  role = excluded.role;

insert into public.messages (
  message_id,
  sender_id,
  receiver_id,
  class_group_id,
  text,
  created_at
) values
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    null,
    'mock_4am_a_arabic',
    'صباح الخير يا أبطال. درس اليوم حول الفكرة العامة والأفكار الأساسية في النص.',
    now() - interval '2 days 4 hours'
  ),
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
    '0d9875ab-94ff-4a3c-b88b-40a9936ece3e',
    null,
    'mock_4am_a_arabic',
    'صباح النور أستاذة، هل نكتب الأفكار في كراس الدروس؟',
    now() - interval '2 days 3 hours 54 minutes'
  ),
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    null,
    'mock_4am_a_arabic',
    'نعم، اكتبوا الفكرة العامة ثم ثلاث أفكار أساسية مع مثال من النص.',
    now() - interval '2 days 3 hours 48 minutes'
  ),
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb4',
    '0f53fe9b-ea28-490b-bef2-532cb8c4e607',
    null,
    'mock_4am_a_arabic',
    'لم أفهم الفرق بين الفكرة العامة والمغزى، هل يمكن توضيح ذلك؟',
    now() - interval '1 day 5 hours'
  ),
  (
    'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb5',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    null,
    'mock_4am_a_arabic',
    'الفكرة العامة تلخص موضوع النص، أما المغزى فهو الدرس أو القيمة التي نستفيدها منه.',
    now() - interval '1 day 4 hours 52 minutes'
  )
on conflict (message_id) do update set
  text = excluded.text,
  created_at = excluded.created_at;

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
  (
    'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
    'arabic',
    'type_0',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    'mock_4am_a_arabic',
    'تحليل نص: قيمة العلم',
    'خريطة ذهنية تساعد الطالب على استخراج عناصر النص وفهم علاقاتها.',
    now() - interval '5 days',
    now()
  ),
  (
    'cccccccc-cccc-4ccc-8ccc-ccccccccccc2',
    'history_geography',
    'type_5',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    'mock_4am_a_arabic',
    'مراحل الثورة التحريرية',
    'خط زمني مختصر لأهم مراحل الثورة التحريرية الجزائرية.',
    now() - interval '4 days',
    now()
  ),
  (
    'cccccccc-cccc-4ccc-8ccc-ccccccccccc3',
    'arabic',
    'type_11',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    'mock_4am_a_arabic',
    'المثلث التعليمي: النص الحجاجي',
    'تنظيم خصائص النص الحجاجي في ثلاثة محاور مترابطة.',
    now() - interval '3 days',
    now()
  )
on conflict (lesson_id) do update set
  subject = excluded.subject,
  strategy_type = excluded.strategy_type,
  teacher_id = excluded.teacher_id,
  class_group_id = excluded.class_group_id,
  title = excluded.title,
  description = excluded.description,
  updated_at = now();

insert into public.lesson_strategies (
  lesson_strategy_id,
  lesson_id,
  strategy_type,
  title,
  content_json,
  created_at,
  updated_at
) values
  (
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd1',
    'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
    'type_0',
    'خريطة ذهنية: قيمة العلم',
    '{
      "id": "root",
      "content": "قيمة العلم",
      "nodes": [
        {
          "id": "idea",
          "content": "الفكرة العامة",
          "nodes": [
            {"id": "idea-1", "content": "العلم طريق التقدم وبناء المجتمع", "nodes": []}
          ]
        },
        {
          "id": "values",
          "content": "القيم",
          "nodes": [
            {"id": "values-1", "content": "الاجتهاد", "nodes": []},
            {"id": "values-2", "content": "المسؤولية", "nodes": []},
            {"id": "values-3", "content": "خدمة الوطن", "nodes": []}
          ]
        },
        {
          "id": "evidence",
          "content": "شواهد من النص",
          "nodes": [
            {"id": "evidence-1", "content": "دعوة الكاتب إلى طلب العلم", "nodes": []},
            {"id": "evidence-2", "content": "ربط العلم بالنهضة", "nodes": []}
          ]
        }
      ]
    }'::jsonb,
    now() - interval '5 days',
    now()
  ),
  (
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd2',
    'cccccccc-cccc-4ccc-8ccc-ccccccccccc2',
    'type_5',
    'خط زمني: الثورة التحريرية',
    '{
      "content": "مراحل الثورة التحريرية",
      "nodes": [
        {"id": "ev-1", "date": "1954-11-01", "content": "اندلاع الثورة التحريرية", "nodes": []},
        {"id": "ev-2", "date": "1956-08-20", "content": "انعقاد مؤتمر الصومام", "nodes": []},
        {"id": "ev-3", "date": "1958-09-19", "content": "تأسيس الحكومة المؤقتة", "nodes": []},
        {"id": "ev-4", "date": "1962-07-05", "content": "استرجاع السيادة الوطنية", "nodes": []}
      ]
    }'::jsonb,
    now() - interval '4 days',
    now()
  ),
  (
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd3',
    'cccccccc-cccc-4ccc-8ccc-ccccccccccc3',
    'type_11',
    'المثلث التعليمي: النص الحجاجي',
    '{
      "title": "النص الحجاجي",
      "description": "فهم النص الحجاجي من خلال الدعوى والحجج والنتيجة.",
      "triangleMap": [
        {
          "corner": "الدعوى",
          "title": "الفكرة التي يدافع عنها الكاتب",
          "description": "موقف واضح يريد الكاتب إقناع القارئ به.",
          "examples": ["العلم أساس النهضة", "التعاون يقوي المجتمع"],
          "color": "#781226"
        },
        {
          "corner": "الحجج",
          "title": "الأدلة والبراهين",
          "description": "أمثلة أو حقائق أو أقوال تدعم الدعوى.",
          "examples": ["أمثلة من الواقع", "إحصاءات", "شواهد"],
          "color": "#C99A34"
        },
        {
          "corner": "النتيجة",
          "title": "الخلاصة",
          "description": "ما يصل إليه الكاتب بعد عرض حججه.",
          "examples": ["دعوة إلى العمل", "تأكيد قيمة معينة"],
          "color": "#0EA5E9"
        }
      ],
      "edgeRelations": {
        "top_left": "تدعم",
        "top_right": "تقود إلى",
        "left_right": "تثبت"
      }
    }'::jsonb,
    now() - interval '3 days',
    now()
  ),
  (
    'dddddddd-dddd-4ddd-8ddd-ddddddddddd4',
    'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
    'type_10',
    'مقارنة: الفكرة العامة والمغزى',
    '{
      "title": "الفكرة العامة والمغزى",
      "comparisonTable": [
        {
          "التعريف": {
            "الفكرة العامة": "تلخيص موضوع النص في عبارة قصيرة",
            "المغزى": "العبرة أو القيمة المستفادة من النص"
          }
        },
        {
          "السؤال المناسب": {
            "الفكرة العامة": "عم يتحدث النص؟",
            "المغزى": "ماذا نتعلم من النص؟"
          }
        },
        {
          "مثال": {
            "الفكرة العامة": "أهمية العلم في تقدم الأمم",
            "المغزى": "ينبغي طلب العلم والعمل به"
          }
        }
      ]
    }'::jsonb,
    now() - interval '5 days',
    now()
  )
on conflict (lesson_strategy_id) do update set
  lesson_id = excluded.lesson_id,
  strategy_type = excluded.strategy_type,
  title = excluded.title,
  content_json = excluded.content_json,
  updated_at = now();

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
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1',
    'arabic',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    'mock_4am_a_arabic',
    'واجب: تحليل نص قيمة العلم',
    'أجب عن الأسئلة ثم اكتب فقرة قصيرة حول أهمية العلم.',
    'active',
    null,
    now() - interval '2 days',
    now() + interval '5 days',
    2,
    now(),
    '{
      "questions": [
        {
          "id": "q-main-idea",
          "type": "mcq",
          "prompt": "ما الفكرة العامة المناسبة للنص؟",
          "options": [
            "أهمية العلم في بناء الفرد والمجتمع",
            "وصف رحلة في الطبيعة",
            "شرح قواعد الإملاء"
          ]
        },
        {
          "id": "q-values",
          "type": "multi_select",
          "prompt": "اختر القيم التي يدعو إليها النص.",
          "options": ["طلب العلم", "الاجتهاد", "الكسل", "خدمة الوطن"]
        },
        {
          "id": "q-true",
          "type": "true_false",
          "prompt": "المغزى هو العبرة المستفادة من النص."
        },
        {
          "id": "q-paragraph",
          "type": "paragraph",
          "prompt": "اكتب فقرة من ثلاثة أسطر حول دور العلم في حياة الطالب."
        }
      ]
    }'::jsonb
  ),
  (
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee2',
    'history_geography',
    '9ef3d541-f264-4181-a2bd-62f90751e1a4',
    'mock_4am_a_arabic',
    'واجب: مراحل الثورة التحريرية',
    'رتب الأحداث وأجب عن سؤالين قصيرين حول الثورة التحريرية.',
    'active',
    null,
    now() - interval '1 day',
    now() + interval '7 days',
    1,
    now(),
    '{
      "questions": [
        {
          "id": "q-date",
          "type": "mcq",
          "prompt": "متى اندلعت الثورة التحريرية؟",
          "options": ["1 نوفمبر 1954", "5 جويلية 1962", "20 أوت 1956"]
        },
        {
          "id": "q-number",
          "type": "number",
          "prompt": "كم سنة دامت الثورة التحريرية تقريبا؟",
          "allow_decimal": false,
          "min": 1,
          "max": 10
        },
        {
          "id": "q-short",
          "type": "short_text",
          "prompt": "اذكر نتيجة مهمة من نتائج مؤتمر الصومام."
        }
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

insert into public.assignment_shares (
  id,
  assignment_id,
  user_id,
  created_at,
  updated_at
) values
  (
    'ffffffff-ffff-4fff-8fff-fffffffffff1',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1',
    '0d9875ab-94ff-4a3c-b88b-40a9936ece3e',
    now() - interval '2 days',
    now()
  ),
  (
    'ffffffff-ffff-4fff-8fff-fffffffffff2',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1',
    '0f53fe9b-ea28-490b-bef2-532cb8c4e607',
    now() - interval '2 days',
    now()
  ),
  (
    'ffffffff-ffff-4fff-8fff-fffffffffff3',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee2',
    '0d9875ab-94ff-4a3c-b88b-40a9936ece3e',
    now() - interval '1 day',
    now()
  )
on conflict (assignment_id, user_id) do update set
  updated_at = now();

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
    '99999999-9999-4999-8999-999999999991',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1',
    '0d9875ab-94ff-4a3c-b88b-40a9936ece3e',
    'أمين سليماني',
    '',
    now() - interval '1 day 3 hours',
    'reviewed',
    'إجابات جيدة، اهتم أكثر بتفصيل الفقرة.',
    now() - interval '1 day 3 hours',
    now(),
    '{
      "answers": [
        {"question_id": "q-main-idea", "type": "mcq", "value": "أهمية العلم في بناء الفرد والمجتمع"},
        {"question_id": "q-values", "type": "multi_select", "value": ["طلب العلم", "الاجتهاد", "خدمة الوطن"]},
        {"question_id": "q-true", "type": "true_false", "value": true},
        {"question_id": "q-paragraph", "type": "paragraph", "value": "العلم يساعد الطالب على فهم العالم من حوله. وبالعلم يستطيع الإنسان تطوير نفسه وخدمة وطنه. لذلك يجب علينا الاجتهاد والمثابرة."}
      ]
    }'::jsonb
  ),
  (
    '99999999-9999-4999-8999-999999999992',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee1',
    '0f53fe9b-ea28-490b-bef2-532cb8c4e607',
    'سارة قادري',
    '',
    now() - interval '18 hours',
    'pending',
    null,
    now() - interval '18 hours',
    now(),
    '{
      "answers": [
        {"question_id": "q-main-idea", "type": "mcq", "value": "أهمية العلم في بناء الفرد والمجتمع"},
        {"question_id": "q-values", "type": "multi_select", "value": ["طلب العلم", "الاجتهاد"]},
        {"question_id": "q-true", "type": "true_false", "value": true},
        {"question_id": "q-paragraph", "type": "paragraph", "value": "العلم نور لأنه يفتح أمامنا أبواب المعرفة. يساعدنا على النجاح وفهم الدروس والتعامل مع الحياة بثقة."}
      ]
    }'::jsonb
  ),
  (
    '99999999-9999-4999-8999-999999999993',
    'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeee2',
    '0d9875ab-94ff-4a3c-b88b-40a9936ece3e',
    'أمين سليماني',
    '',
    now() - interval '6 hours',
    'pending',
    null,
    now() - interval '6 hours',
    now(),
    '{
      "answers": [
        {"question_id": "q-date", "type": "mcq", "value": "1 نوفمبر 1954"},
        {"question_id": "q-number", "type": "number", "value": 8},
        {"question_id": "q-short", "type": "short_text", "value": "تنظيم الثورة سياسيا وعسكريا وتحديد هياكلها."}
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
