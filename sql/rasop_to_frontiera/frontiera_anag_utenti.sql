INSERT INTO hcbi_ras.frontiera_anag_utenti (
    user_id, username, email, display_name, state, usertype
)
SELECT
    u.user_id::character varying(100) AS user_id,
    u.username,
    u.email,
    u.display_name,
    u.state::character varying(20) AS state,
    u.usertype
FROM public."user" AS u
ORDER BY u.user_id;
