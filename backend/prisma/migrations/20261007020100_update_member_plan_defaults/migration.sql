CREATE TEMPORARY TABLE legacy_member_plan_defaults (
    admin_id BIGINT UNSIGNED NOT NULL PRIMARY KEY
);

INSERT INTO legacy_member_plan_defaults (admin_id)
SELECT admin_id
FROM plans
GROUP BY admin_id
HAVING COUNT(*) = 4
   AND SUM(CASE WHEN duration_value = 1 AND duration_unit = 'MONTH' AND fee = 65 THEN 1 ELSE 0 END) = 1
   AND SUM(CASE WHEN duration_value = 3 AND duration_unit = 'MONTH' AND fee = 180 THEN 1 ELSE 0 END) = 1
   AND SUM(CASE WHEN duration_value = 6 AND duration_unit = 'MONTH' AND fee = 340 THEN 1 ELSE 0 END) = 1
   AND SUM(CASE WHEN duration_value = 12 AND duration_unit = 'MONTH' AND fee = 620 THEN 1 ELSE 0 END) = 1;

DELETE plan
FROM plans AS plan
JOIN legacy_member_plan_defaults AS defaults ON defaults.admin_id = plan.admin_id;

INSERT INTO plans (admin_id, duration_value, duration_unit, fee)
SELECT admin_id, 1, 'DAY', 400 FROM legacy_member_plan_defaults
UNION ALL
SELECT admin_id, 1, 'WEEK', 2500 FROM legacy_member_plan_defaults
UNION ALL
SELECT admin_id, 1, 'MONTH', 10000 FROM legacy_member_plan_defaults
UNION ALL
SELECT admin_id, 3, 'MONTH', 25000 FROM legacy_member_plan_defaults;

DROP TEMPORARY TABLE legacy_member_plan_defaults;
