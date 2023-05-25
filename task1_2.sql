create sequence week_id_seq
    as integer;

alter sequence week_id_seq owner to alex;

create type work_week as enum ('Понедельник', 'Вторник', 'Среда', 'Четверг', 'Пятница');

alter type work_week owner to alex;

create type video_card as
(
    model  varchar(255),
    volume integer,
    price  money
);

alter type video_card owner to alex;

create table photo
(
    id   serial
        constraint photo_pk
            primary key,
    path varchar(255) not null,
    size varchar(255) not null
);

alter table photo
    owner to alex;

create table "user"
(
    surname    varchar(255),
    name       varchar(255) not null,
    patronymic varchar(255) not null,
    role       varchar(255) not null,
    password   varchar(255) not null,
    email      varchar(255) not null,
    id         serial
        constraint user_pk
            primary key,
    post       varchar(255),
    photo_id   integer
        constraint user_photo_id_fk
            references photo
);

alter table "user"
    owner to alex;

create table plan
(
    id          serial
        constraint plan_pk
            primary key,
    description text,
    start       date         not null,
    finish      date         not null,
    name        varchar(255) not null
);

alter table plan
    owner to alex;

create table plan_type
(
    plan_type boolean not null,
    id        serial
        constraint plan_type_pk
            primary key,
    plan      integer
        constraint plan__fk
            references plan
);

alter table plan_type
    owner to alex;

create table material
(
    id     serial
        constraint material_pk
            primary key,
    source varchar(255) not null
);

alter table material
    owner to alex;

create table stage
(
    id          serial
        constraint stage_pk
            primary key,
    description varchar(255) not null,
    date        timestamp    not null,
    actions     json,
    material    integer
        constraint stage_material_fk
            references material,
    type        integer
        constraint stage_type__fk
            references plan_type
);

alter table stage
    owner to alex;

create table stage_feedback
(
    id      serial
        constraint stage_feedback_pk
            primary key,
    comment varchar(255),
    grade   smallint  not null,
    date    timestamp not null,
    stage   integer   not null
        constraint stage_feedback__fk
            references stage,
    "user"  integer   not null
        constraint user_feedback__fk
            references "user"
);

alter table stage_feedback
    owner to alex;

create table user_feedback
(
    id              serial
        constraint user_feedback_pk
            primary key,
    comment         varchar(255),
    grade           smallint  not null,
    date            timestamp not null,
    leader          integer   not null
        constraint user_feedback_leader__fk
            references "user",
    novice_feedback integer   not null
        constraint user_feedback_novice__fk
            references stage_feedback
);

alter table user_feedback
    owner to alex;

create table day
(
    id     integer default nextval('week_id_seq'::regclass) not null,
    number integer,
    week   work_week
);

alter table day
    owner to alex;

alter sequence week_id_seq owned by day.id;

create table faq
(
    chapter  integer,
    question text[]
);

alter table faq
    owner to alex;

create table clients
(
    number_of_order integer,
    "client-data"   xml
);

alter table clients
    owner to alex;

create table computer
(
    video video_card,
    name  varchar(255)
);

alter table computer
    owner to alex;

create table delete_causes
(
    uid    uuid,
    causes bit(5)
);

alter table delete_causes
    owner to alex;

create table ascii_image
(
    position point,
    symbol   bytea
);

alter table ascii_image
    owner to alex;

create table pocket_money
(
    number  integer not null,
    price   integer,
    balance integer
);

alter table pocket_money
    owner to alex;

create table order_history
(
    id         integer,
    order_id   integer,
    created_at date,
    field_name varchar(255),
    old_value  varchar(255),
    new_value  varchar(255)
);

alter table order_history
    owner to alex;

create table names
(
    id   integer not null
        primary key,
    name char(20)
);

alter table names
    owner to alex;

create table surnames
(
    id      integer not null
        primary key,
    surname char(30)
);

alter table surnames
    owner to alex;

create table patronymics
(
    id         integer not null
        primary key,
    patronymic char(30)
);

alter table patronymics
    owner to alex;

create table person_data
(
    id         integer,
    surname    char(30),
    name       char(20),
    patronymic char(30),
    role       char(20),
    password   text,
    email      text,
    post       text
);

alter table person_data
    owner to alex;

create index surname_index
    on person_data (surname);

create index id_index
    on person_data using hash (id);

create index role_index
    on person_data using brin (role);

create index not_correct_email
    on person_data (email)
    where (char_length(email) < 11);

create table table_for_gin
(
    id  integer,
    arr text[]
);

alter table table_for_gin
    owner to alex;

create index gin_index
    on table_for_gin using gin (arr);

create table gist_table
(
    id       integer,
    response jsonb
);

alter table gist_table
    owner to alex;

create index gist_index
    on gist_table using gin (response);

