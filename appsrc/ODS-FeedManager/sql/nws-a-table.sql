--
--  $Id$
--
--  This file is part of the OpenLink Software Virtuoso Open-Source (VOS)
--  project.
--
--  Copyright (C) 1998-2006 OpenLink Software
--
--  This project is free software; you can redistribute it and/or modify it
--  under the terms of the GNU General Public License as published by the
--  Free Software Foundation; only version 2 of the License, dated June 1991.
--
--  This program is distributed in the hope that it will be useful, but
--  WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
--  General Public License for more details.
--
--  You should have received a copy of the GNU General Public License along
--  with this program; if not, write to the Free Software Foundation, Inc.,
--  51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
--

-------------------------------------------------------------------------------
--
-- Conatins all subscribed feeds
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.FEED (
  	EF_ID integer identity,
    EF_URI varchar not null,
    EF_HOME_URI varchar,
    EF_SOURCE_URI varchar,
    EF_TITLE varchar,
    EF_DESCRIPTION varchar,
    EF_COPYRIGHT varchar,
    EF_CSS varchar,
    EF_FORMAT varchar,
    EF_LANG varchar default \'us-en\',
    EF_UPDATE_PERIOD varchar default \'hourly\',
    EF_UPDATE_FREQ integer default 1,
    EF_STORE_DAYS integer default 30,
    EF_TAG varchar,
    EF_LAST_UPDATE datetime,
    EF_QUEUE_FLAG integer,
    EF_UPDATE integer,
    EF_ERROR_LOG long varchar default null,
    EF_DATA long xml,
    EF_DASHBOARD long varchar,

    primary key (EF_ID)
  )
');

ENEWS.WA.exec_no_error('
  create unique index SK_FEED_01 on ENEWS.WA.FEED(EF_URI)
');

ENEWS.WA.exec_no_error('
  create trigger FEED_INSERT AFTER INSERT ON ENEWS.WA.FEED referencing new as N {
    ENEWS.WA.channel_trigger (N.EF_ID, N.EF_UPDATE_PERIOD, N.EF_UPDATE_FREQ);
  }
');

ENEWS.WA.exec_no_error('
  create trigger FEED_UPDATE AFTER UPDATE on ENEWS.WA.FEED referencing old as O, new as N {
    if ((O.EF_UPDATE_PERIOD <> N.EF_UPDATE_PERIOD) or (O.EF_UPDATE_FREQ <> N.EF_UPDATE_FREQ))
      ENEWS.WA.channel_trigger (N.EF_ID, N.EF_UPDATE_PERIOD, N.EF_UPDATE_FREQ);
  }
');

ENEWS.WA.exec_no_error(
  'alter table ENEWS.WA.FEED add EF_DASHBOARD long varchar', 'C', 'ENEWS.WA.FEED', 'EF_DASHBOARD'
);


-------------------------------------------------------------------------------
--
create procedure ENEWS.WA.channel_trigger (
  in id any,
  in period any,
  in freq any)
{
  declare upd int;

  period := lower (coalesce (period, 'daily'));

  -- Hourly, Daily, Weekly, Monthly, Yearly
  upd := case period
           when 'hourly' then 60
           when 'daily' then 1440
           when 'weekly' then 10080
           when 'monthly' then 43200
           when 'yearly' then 525600
           else 1440
         end;
  upd := upd / freq;
  set triggers off;

  update ENEWS.WA.FEED
     set EF_UPDATE = upd
   where EF_ID = id;
};

-------------------------------------------------------------------------------
--
-- Conatins all items from all subscribed feeds
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.FEED_ITEM (
  	EFI_ID integer identity,
  	EFI_FEED_ID integer not null,
  	EFI_TITLE varchar,
  	EFI_DESCRIPTION long xml,
  	EFI_LINK varchar,
  	EFI_GUID varchar,
  	EFI_COMMENT_API varchar,
  	EFI_COMMENT_RSS varchar,
    EFI_PUBLISH_DATE datetime,
    EFI_AUTHOR varchar,
    EFI_LAST_UPDATE datetime,
    EFI_DELETE_FLAG integer,
    EFI_ENCLOSURE integer,
    EFI_DATA long xml,

    constraint FK_FEED_ITEM_01 FOREIGN KEY (EFI_FEED_ID) references ENEWS.WA.FEED (EF_ID) ON DELETE CASCADE,

  	primary key (EFI_ID)
  )
');

ENEWS.WA.exec_no_error(
  'alter table ENEWS.WA.FEED_ITEM add EFI_ENCLOSURE integer', 'C', 'ENEWS.WA.FEED_ITEM', 'EFI_ENCLOSURE'
);

ENEWS.WA.exec_no_error('
  create trigger ENEWS_FEED_ITEM_WA_IN after insert on ENEWS.WA.FEED_ITEM referencing new as N {
    update ENEWS.WA.FEED
      set EF_DASHBOARD = ENEWS.WA.make_dasboard_item (EF_DASHBOARD, N.EFI_PUBLISH_DATE, N.EFI_TITLE, N.EFI_AUTHOR, N.EFI_DATA, sprintf(\'/enews2/news.vspx?link=%d\', N.EFI_ID), N.EFI_ID)
     where EF_ID = N.EFI_FEED_ID;
    if (__proc_exists (\'DB.DBA.WA_NEW_NEWS_IN\'))
      DB.DBA.WA_NEW_NEWS_IN (ENEWS.WA.show_title(N.EFI_TITLE), sprintf(\'/enews2/news.vspx?link=%d\', N.EFI_ID), N.EFI_ID);
  }
');

ENEWS.WA.exec_no_error('
  create trigger ENEWS_FEED_ITEM_WA_DEL after delete on ENEWS.WA.FEED_ITEM referencing old as O {
    update ENEWS.WA.FEED
       set EF_DASHBOARD = ENEWS.WA.make_dasboard_item (EF_DASHBOARD, null, null, null, null, null, O.EFI_ID, \'delete\')
   	 where EF_ID = O.EFI_FEED_ID;
    if (__proc_exists (\'DB.DBA.WA_NEW_NEWS_RM\'))
      DB.DBA.WA_NEW_NEWS_RM (O.EFI_ID);
  }
');

ENEWS.WA.exec_no_error('
  create index SK_FEED_ITEM_01 on ENEWS.WA.FEED_ITEM (EFI_FEED_ID, EFI_ID)
');

-------------------------------------------------------------------------------
--
-- Conatins directory structure
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.DIRECTORY (
  	ED_ID integer identity,
  	ED_PARENT_ID integer,
  	ED_NAME varchar not null,

  	primary key (ED_ID)
  )
');

ENEWS.WA.exec_no_error('
  create unique index SK_DIRECTORY_01 on ENEWS.WA.DIRECTORY(ED_PARENT_ID, ED_NAME)
');

-------------------------------------------------------------------------------
--
-- Conatins feeds directories
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.FEED_DIRECTORY (
  	EFD_DIRECTORY_ID integer not null,
  	EFD_FEED_ID integer not null,

    constraint FK_FEED_DIRECTORY_01 FOREIGN KEY (EFD_FEED_ID) references ENEWS.WA.FEED (EF_ID) on delete cascade,
    constraint FK_FEED_DIRECTORY_02 FOREIGN KEY (EFD_DIRECTORY_ID) references ENEWS.WA.DIRECTORY (ED_ID) on delete cascade,

    primary key ( EFD_DIRECTORY_ID, EFD_FEED_ID)
  )
');

-------------------------------------------------------------------------------
--
-- Conatins folders structure. Structure is domain specific.
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.FOLDER (
  	EFO_DOMAIN_ID integer not null,
  	EFO_ID integer identity,
  	EFO_PARENT_ID integer,
  	EFO_NAME varchar not null,

  	primary key (EFO_DOMAIN_ID, EFO_ID)
  )
');

ENEWS.WA.exec_no_error('
  create unique index SK_FOLDER_01 on ENEWS.WA.FOLDER(EFO_DOMAIN_ID, EFO_PARENT_ID, EFO_NAME)
');

-------------------------------------------------------------------------------
--
-- Conatins smart folders structure. Structure is domain specific.
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.SFOLDER (
  	ESFO_DOMAIN_ID integer not null,
  	ESFO_ID varchar not null,
  	ESFO_NAME varchar not null,
  	ESFO_DATA long varchar,

  	primary key (ESFO_DOMAIN_ID, ESFO_ID)
  )
');

ENEWS.WA.exec_no_error('
  create unique index SK_SFOLDER_01 on ENEWS.WA.SFOLDER(ESFO_DOMAIN_ID, ESFO_NAME)
');

-------------------------------------------------------------------------------
--
-- Conatins domain feeds.
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.FEED_DOMAIN (
    EFD_ID integer identity,
  	EFD_DOMAIN_ID integer not null,
  	EFD_FEED_ID integer not null,
    EFD_TITLE varchar,
    EFD_TAGS varchar,
  	EFD_FOLDER_ID integer,

    constraint FK_FEED_DOMAIN_01 FOREIGN KEY (EFD_FEED_ID) references ENEWS.WA.FEED (EF_ID),
    constraint FK_FEED_DOMAIN_02 FOREIGN KEY (EFD_DOMAIN_ID, EFD_FOLDER_ID) references ENEWS.WA.FOLDER (EFO_DOMAIN_ID, EFO_ID) on delete set null,

    primary key (EFD_ID)
  )
');



ENEWS.WA.exec_no_error('
  drop index SK_FEED_DOMAIN_01 ENEWS.WA.FEED_DOMAIN
');

ENEWS.WA.exec_no_error('
  create index SK_FEED_DOMAIN_01 on ENEWS.WA.FEED_DOMAIN(EFD_DOMAIN_ID, EFD_FEED_ID)
');

-------------------------------------------------------------------------------
--
-- Conatins specific data for feed items and domain/user - flags, tags and etc.
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.FEED_ITEM_DATA (
  	EFID_ID integer identity,
  	EFID_DOMAIN_ID integer,
  	EFID_ACCOUNT_ID integer,
  	EFID_ITEM_ID integer not null,
  	EFID_READ_FLAG integer,
  	EFID_KEEP_FLAG integer,
  	EFID_TAGS varchar,
    EFID_LAST_UPDATE datetime,

    constraint FK_FEED_ITEM_DATA_01 FOREIGN KEY (EFID_ITEM_ID) references ENEWS.WA.FEED_ITEM (EFI_ID) on delete cascade,

  	primary key (EFID_ID)
  )
');

ENEWS.WA.exec_no_error(
  'alter table ENEWS.WA.FEED_ITEM_DATA add EFID_LAST_UPDATE datetime', 'C', 'ENEWS.WA.FEED_ITEM_DATA', 'EFID_LAST_UPDATE'
);

ENEWS.WA.exec_no_error('
  drop index SK_FEED_ITEM_DATA_01 ENEWS.WA.FEED_ITEM_DATA
');

ENEWS.WA.exec_no_error('
  drop index SK_FEED_ITEM_DATA_02 ENEWS.WA.FEED_ITEM_DATA
');

ENEWS.WA.exec_no_error ('
  create index SK_FEED_ITEM_DATA_01 on ENEWS.WA.FEED_ITEM_DATA(EFID_ITEM_ID)
');

-------------------------------------------------------------------------------
--
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.FEED_ITEM_COMMENT (
  	EFIC_ID integer identity,
    EFIC_PARENT_ID integer default null,
  	EFIC_DOMAIN_ID integer not null,
    EFIC_ITEM_ID varchar not null,
    EFIC_TITLE varchar,
    EFIC_COMMENT long varchar,
    EFIC_U_NAME varchar,
    EFIC_U_MAIL varchar,
    EFIC_U_URL varchar,
    EFIC_LAST_UPDATE datetime,
    EFIC_RFC_ID varchar,
    EFIC_RFC_HEADER long varchar,
    EFIC_RFC_REFERENCES varchar default null,

    constraint FK_FEED_ITEM_COMMENT_01 FOREIGN KEY (EFIC_ITEM_ID) references ENEWS.WA.FEED_ITEM (EFI_ID) on delete cascade,

  	primary key (EFIC_ID)
  )
');

ENEWS.WA.exec_no_error('
  create unique index SK_FEED_ITEM_COMMENT_01 on ENEWS.WA.FEED_ITEM_COMMENT(EFIC_DOMAIN_ID, EFIC_ITEM_ID, EFIC_ID)
');

ENEWS.WA.exec_no_error('
  create trigger FEED_ITEM_COMMENT_I after insert on ENEWS.WA.FEED_ITEM_COMMENT referencing new as N {
    declare id integer;
    declare rfc_id, rfc_header, rfc_references varchar;
    declare nInstance any;

    nInstance := ENEWS.WA.domain_name(N.EFIC_DOMAIN_ID);
    id := N.EFIC_ID;
    rfc_id := N.EFIC_RFC_ID;
    if (isnull(rfc_id))
      rfc_id := ENEWS.WA.make_rfc_id (N.EFIC_ITEM_ID, N.EFIC_ID);

    rfc_references := \'\';
    if (N.EFIC_PARENT_ID) {
      declare p_rfc_id, p_rfc_references any;

      --declare exit handler for not found;

      select EFIC_RFC_ID, EFIC_RFC_REFERENCES
        into p_rfc_id, p_rfc_references
        from ENEWS.WA.FEED_ITEM_COMMENT
  	   where EFIC_ID = N.EFIC_PARENT_ID;
      if (isnull(p_rfc_references))
       	p_rfc_references := rfc_references;
      rfc_references :=  p_rfc_references || \' \' || p_rfc_id;
    }

    rfc_header := N.EFIC_RFC_HEADER;
    if (isnull(rfc_header))
      rfc_header := ENEWS.WA.make_post_rfc_header (rfc_id, rfc_references, nInstance, N.EFIC_TITLE, N.EFIC_LAST_UPDATE, N.EFIC_U_MAIL);

    set triggers off;
    update ENEWS.WA.FEED_ITEM_COMMENT
       set EFIC_RFC_ID = rfc_id,
  	       EFIC_RFC_HEADER = rfc_header,
  	       EFIC_RFC_REFERENCES = rfc_references
     where EFIC_ID = id;
    set triggers on;
  }
');

ENEWS.WA.exec_no_error('
  create trigger FEED_ITEM_COMMENT_NEWS_I after insert on ENEWS.WA.FEED_ITEM_COMMENT order 30 referencing new as N {
    declare grp, ngnext integer;
    declare rfc_id, nInstance any;

    declare exit handler for not found { return;};

    nInstance := ENEWS.WA.domain_name(N.EFIC_DOMAIN_ID);
    select NG_GROUP, NG_NEXT_NUM into grp, ngnext from DB..NEWS_GROUPS where NG_NAME = nInstance;
    if (ngnext < 1)
      ngnext := 1;
    rfc_id := (select EFIC_RFC_ID from ENEWS.WA.FEED_ITEM_COMMENT where EFIC_ID = N.EFIC_ID);

    insert into DB.DBA.NEWS_MULTI_MSG (NM_KEY_ID, NM_GROUP, NM_NUM_GROUP)
      values (rfc_id, grp, ngnext);

    set triggers off;
    update DB.DBA.NEWS_GROUPS
       set NG_NEXT_NUM = ngnext + 1
     where NG_NAME = nInstance;
    DB.DBA.ns_up_num (grp);
    set triggers on;
  }
');

ENEWS.WA.exec_no_error('
  create trigger FEED_ITEM_COMMENT_D after delete on ENEWS.WA.FEED_ITEM_COMMENT referencing old as O {

    -- update all that have EFIC_PARENT_ID == O.EFIC_PARENT_ID
    set triggers off;
    update ENEWS.WA.FEED_ITEM_COMMENT
       set EFIC_PARENT_ID = O.EFIC_PARENT_ID
     where EFIC_PARENT_ID = O.EFIC_ID;
    set triggers on;
  }
');

ENEWS.WA.exec_no_error('
  create trigger FEED_ITEM_COMMENT_NEWS_D after delete on ENEWS.WA.FEED_ITEM_COMMENT order 30 referencing old as O {
    declare grp integer;
    declare oInstance any;

    oInstance := ENEWS.WA.domain_name(O.EFIC_DOMAIN_ID);
    grp := (select NG_GROUP from DB..NEWS_GROUPS where NG_NAME = oInstance);
    delete from DB.DBA.NEWS_MULTI_MSG where NM_KEY_ID = O.EFIC_RFC_ID and NM_GROUP = grp;
    DB.DBA.ns_up_num (grp);
  }
');

-------------------------------------------------------------------------------
--
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.TAGS (
  	ETS_DOMAIN_ID integer not null,
  	ETS_ACCOUNT_ID integer not null,
    ETS_LAST_UPDATE datetime,
    ETS_TAG varchar,
  	ETS_COUNT integer,

    primary key (ETS_DOMAIN_ID, ETS_ACCOUNT_ID, ETS_TAG)
  )
');

create procedure ENEWS.WA.TAGS_STATISTICS (
  in domain_id integer,
  in account_id integer)
{
  declare ts_tag varchar;
  declare ts_count integer;

  ENEWS.WA.tags_refresh (domain_id, account_id, 1);
  result_names (ts_tag, ts_count);
  for (select ETS_TAG, ETS_COUNT FROM ENEWS.WA.TAGS where ETS_DOMAIN_ID = domain_id and ETS_ACCOUNT_ID = account_id) do
    result (ETS_TAG, ETS_COUNT);
}
;

ENEWS.WA.exec_no_error('
  create procedure view ENEWS..TAGS_STATISTICS as ENEWS.WA.TAGS_STATISTICS (domain_id, account_id) (TS_TAG varchar, TS_COUNT integer)
');

-------------------------------------------------------------------------------
--
-- Conatins settings.
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.SETTINGS (
    ES_DOMAIN_ID integer not null,
    ES_ACCOUNT_ID integer not null,
    ES_DATA varchar,

    primary key(ES_DOMAIN_ID, ES_ACCOUNT_ID)
  )
');

-------------------------------------------------------------------------------
--
-- Conatins domain weblogs
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.WEBLOG (
  	EW_ID integer identity,
    EW_DOMAIN_ID integer not null,
    EW_NAME varchar not null,                    -- Weblog name
    EW_API varchar not null,                     -- API name (Blogger, metaBlogs and etc.
    EW_URI varchar not null,                     -- Weblog URI
    EW_PORT varchar,                             -- Weblog post
    EW_ENDPOINT varchar,                         -- Weblog endpoint
    EW_USER varchar,                             -- Weblog user name
    EW_PASSWORD varchar,                         -- Weblog user password
    EW_LAST_UPDATE datetime,
    EW_ERROR_LOG long varchar,

    primary key (EW_ID)
  )
');

ENEWS.WA.exec_no_error('
  create unique index SK_WEBLOG_01 on ENEWS.WA.WEBLOG(EW_DOMAIN_ID, EW_NAME)
');

-------------------------------------------------------------------------------
--
-- Conatins weblog blogs
--
-------------------------------------------------------------------------------
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.BLOG (
  	EB_ID integer identity,
    EB_WEBLOG_ID integer not null,
    EB_NAME varchar not null,            -- Blog name
    EB_BLOGID varchar,                   -- Unique blog id
    EB_URI varchar,                      -- Blog home uri
    EB_LIMIT integer default 5,          -- Number of posts for get
    EB_UPDATE_PERIOD varchar default \'daily\',
    EB_UPDATE_FREQ integer default 1,
    EB_STORE_DAYS integer default 30,
    EB_UPDATE integer,
    EB_LAST_UPDATE datetime,
    EB_QUEUE_FLAG integer,
    EB_ERROR_LOG long varchar,

    constraint FK_BLOG_01 FOREIGN KEY (EB_WEBLOG_ID) references ENEWS.WA.WEBLOG (EW_ID) on delete cascade,

    primary key (EB_ID)
  )
');

ENEWS.WA.exec_no_error('
  create unique index SK_BLOG_01 on ENEWS.WA.BLOG(EB_WEBLOG_ID, EB_NAME)
');

ENEWS.WA.exec_no_error('
  create unique index SK_BLOG_02 on ENEWS.WA.BLOG(EB_WEBLOG_ID, EB_BLOGID)
');

ENEWS.WA.exec_no_error('
  create trigger BLOG_INSERT AFTER INSERT ON ENEWS.WA.BLOG referencing new as N {
    ENEWS.WA.blog_trigger (N.EB_ID, N.EB_UPDATE_PERIOD, N.EB_UPDATE_FREQ);
  }
');

ENEWS.WA.exec_no_error('
  create trigger BLOG_UPDATE AFTER UPDATE on ENEWS.WA.BLOG referencing old as O, new as N {
    if ((O.EB_UPDATE_PERIOD <> N.EB_UPDATE_PERIOD) or (O.EB_UPDATE_FREQ <> N.EB_UPDATE_FREQ))
      ENEWS.WA.blog_trigger (N.EB_ID, N.EB_UPDATE_PERIOD, N.EB_UPDATE_FREQ);
  }
');

create procedure ENEWS.WA.blog_trigger (
  in id any,
  in period any,
  in freq any)
{
  declare upd int;

  period := lower (coalesce (period, 'daily'));

  -- Hourly, Daily, Weekly, Monthly, Yearly
  upd := case period
           when 'hourly' then 60
           when 'daily' then 1440
           when 'weekly' then 10080
           when 'monthly' then 43200
           when 'yearly' then 525600
           else 1440
         end;
  upd := upd / freq;
  set triggers off;

  update ENEWS.WA.BLOG
     set EB_UPDATE = upd
   where EB_ID = id;
};

-------------------------------------------------------------------------------
--
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.BLOG_POST (
  	EBP_ID integer identity,
  	EBP_BLOG_ID integer not null,
  	EBP_POSTID varchar,
    EBP_META BLOG.DBA.MWeblogPost,
    EBP_LAST_UPDATE datetime,

    constraint FK_BLOG_POST_01 FOREIGN KEY (EBP_BLOG_ID) references ENEWS.WA.BLOG (EB_ID) on delete cascade,

  	primary key (EBP_ID)
  )
');

ENEWS.WA.exec_no_error('
  create unique index SK_BLOG_POST_01 on ENEWS.WA.BLOG_POST (EBP_BLOG_ID, EBP_POSTID)
');

-------------------------------------------------------------------------------
--
ENEWS.WA.exec_no_error('
  create table ENEWS.WA.BLOG_POST_DATA (
  	EBPD_ID integer identity,
  	EBPD_DOMAIN_ID integer,
  	EBPD_POST_ID integer not null,
  	EBPD_READ_FLAG integer,
  	EBPD_KEEP_FLAG integer,
  	EBPD_TAGS varchar,

    constraint FK_BLOG_POST_DATA_01 FOREIGN KEY (EBPD_POST_ID) references ENEWS.WA.BLOG_POST (EBP_ID) on delete cascade,

  	primary key (EBPD_ID)
  )
');

ENEWS.WA.exec_no_error('
  create index SK_FEED_ITEM_DATA_01 on ENEWS.WA.BLOG_POST_DATA(EBPD_DOMAIN_ID, EBPD_POST_ID)
');

-------------------------------------------------------------------------------
--
create procedure ENEWS.WA.drop_index()
{
  if (registry_get ('news_index_version') <> '1') {
    ENEWS.WA.exec_no_error('drop table ENEWS.WA.FEED_ITEM_EFI_DESCRIPTION');
  }
}
;

ENEWS.WA.drop_index();

ENEWS.WA.exec_no_error('
  create text xml index on ENEWS.WA.FEED_ITEM(EFI_DESCRIPTION) with key EFI_ID not insert clustered with (EFI_ID, EFI_FEED_ID, EFI_PUBLISH_DATE) using function
');

-------------------------------------------------------------------------------
--
create procedure ENEWS.WA.FEED_ITEM_EFI_DESCRIPTION_index_hook (inout vtb any, inout d_id any)
{
  return ENEWS.WA.FEED_ITEM_EFI_DESCRIPTION_int (vtb, d_id, 0);
}
;

-------------------------------------------------------------------------------
--
create procedure ENEWS.WA.FEED_ITEM_EFI_DESCRIPTION_unindex_hook (inout vtb any, inout d_id any)
{
  return ENEWS.WA.FEED_ITEM_EFI_DESCRIPTION_int (vtb, d_id, 1);
}
;

-------------------------------------------------------------------------------
--
create procedure ENEWS.WA.FEED_ITEM_EFI_DESCRIPTION_int (inout vtb any, inout d_id any, in mode any)
{
  for (select EFI_DESCRIPTION, EFI_FEED_ID, EFI_TITLE, EFI_AUTHOR, EFI_PUBLISH_DATE from ENEWS.WA.FEED_ITEM where EFI_ID = d_id) do {
    vt_batch_feed (vtb, EFI_DESCRIPTION, mode, 1);

    vt_batch_feed (vtb, sprintf ('^F%d', EFI_FEED_ID), mode);

    vt_batch_feed (vtb, coalesce(EFI_TITLE, ''), mode);

    vt_batch_feed (vtb, coalesce(EFI_AUTHOR, ''), mode);

    vt_batch_feed (vtb, ENEWS.WA.dt_format(coalesce(EFI_PUBLISH_DATE, now()), 'YMD'), mode);

    if (exists(select 1 from DB.DBA.WA_INSTANCE where WAI_TYPE_NAME = 'eNews2' and WAI_IS_PUBLIC = 1))
      vt_batch_feed (vtb, '^public', mode);

    for (select EFD_DOMAIN_ID from ENEWS.WA.FEED_DOMAIN where EFD_FEED_ID = EFI_FEED_ID) do
      vt_batch_feed (vtb, sprintf('^R%d', EFD_DOMAIN_ID), mode);

    vt_batch_feed_offband (vtb, serialize (vector (d_id, EFI_FEED_ID, EFI_PUBLISH_DATE)), mode);
  }
  return 1;
}
;

ENEWS.WA.vt_index_ENEWS_WA_FEED_ITEM();
DB.DBA.vt_batch_update('ENEWS.WA.FEED_ITEM', 'off', null);

ENEWS.WA.exec_no_error('
  drop table ENEWS.WA.FEED_ITEM_DATA_EFID_TAGS
');

-------------------------------------------------------------------------------
--
create procedure ENEWS.WA.drop_index()
{
  if (registry_get ('news_index_version') <> '1') {
    ENEWS.WA.exec_no_error('drop table ENEWS.WA.FEED_ITEM_DATA_EFID_TAGS');
  }
}
;
ENEWS.WA.drop_index();

ENEWS.WA.exec_no_error('
  create text index on ENEWS.WA.FEED_ITEM_DATA (EFID_TAGS) with key EFID_ID not insert clustered with (EFID_DOMAIN_ID, EFID_ACCOUNT_ID, EFID_ITEM_ID) using function language \'x-ViDoc\'
');

-------------------------------------------------------------------------------
--
create procedure ENEWS.WA.FEED_ITEM_DATA_EFID_TAGS_index_hook (inout vtb any, inout d_id any)
{
  return ENEWS.WA.FEED_ITEM_DATA_EFID_TAGS_int(vtb, d_id, 0);
}
;

-------------------------------------------------------------------------------
--
create procedure ENEWS.WA.FEED_ITEM_DATA_EFID_TAGS_unindex_hook (inout vtb any, inout d_id any)
{
  return ENEWS.WA.FEED_ITEM_DATA_EFID_TAGS_int(vtb, d_id, 1);
}
;

-------------------------------------------------------------------------------
--
create procedure ENEWS.WA.FEED_ITEM_DATA_EFID_TAGS_int (inout vtb any, inout d_id any, in mode any)
{
  declare domain_id, account_id, item_id, tags any;

  select EFID_DOMAIN_ID, EFID_ACCOUNT_ID, EFID_ITEM_ID, EFID_TAGS into domain_id, account_id, item_id, tags from ENEWS.WA.FEED_ITEM_DATA where EFID_ID = d_id;

  tags := split_and_decode (tags, 0, '\0\0,');
  foreach (any tag in tags) do  {
    tag := trim(tag);
    tag := replace (tag, ' ', '_');
    tag := replace (tag, '+', '_');
    vt_batch_feed (vtb, tag, mode);
  }

  if (isnull(domain_id) and isnull(account_id))
    if (exists(select 1 from DB.DBA.WA_INSTANCE where WAI_TYPE_NAME = 'eNews2' and WAI_IS_PUBLIC = 1))
      vt_batch_feed (vtb, '^public', mode);

  if (not isnull(domain_id)) {
    vt_batch_feed (vtb, sprintf ('^R%d', domain_id), mode);
    if (exists(select 1 from DB.DBA.WA_INSTANCE where WAI_ID = domain_id and WAI_IS_PUBLIC = 1))
      vt_batch_feed (vtb, '^public', mode);
  }

  if (not isnull(account_id))
    vt_batch_feed (vtb, sprintf ('^UID%d', account_id), mode);

  vt_batch_feed (vtb, sprintf ('^I%d', item_id), mode);

  vt_batch_feed_offband (vtb, serialize (vector (domain_id, account_id, item_id)), mode);

  return 1;
}
;

ENEWS.WA.vt_index_ENEWS_WA_FEED_ITEM_DATA();
DB.DBA.vt_batch_update('ENEWS.WA.FEED_ITEM_DATA', 'off', null);


-------------------------------------------------------------------------------
--
ENEWS.WA.exec_no_error('
  create trigger WA_MEMBER_AU_ENEWS AFTER UPDATE ON DB.DBA.WA_MEMBER order 10 referencing old as O, new as N {
    declare domain_id, account_id integer;

    if ((O.WAM_INST <> N.WAM_INST) and (N.WAM_MEMBER_TYPE = 1)) {
      account_id := N.WAM_USER;
      domain_id := (select WAI_ID from DB.DBA.WA_INSTANCE where WAI_NAME = N.WAM_INST);
      ENEWS.WA.domain_gems_delete(domain_id, account_id, \'OFM\', O.WAM_INST || \'_Gems\');
      ENEWS.WA.domain_gems_create(domain_id, account_id);
      ENEWS.WA.nntp_update (domain_id, O.WAM_INST, null, null);
    }
  }
');

-------------------------------------------------------------------------------
--
ENEWS.WA.exec_no_error('
  insert replacing DB.DBA.SYS_SCHEDULED_EVENT (SE_NAME, SE_START, SE_SQL, SE_INTERVAL)
    values(\'eNews feed aggregator\', now(), \'ENEWS.WA.feeds_agregator()\', 30)
')
;

ENEWS.WA.exec_no_error('
  insert replacing DB.DBA.SYS_SCHEDULED_EVENT (SE_NAME, SE_START, SE_SQL, SE_INTERVAL)
    values(\'eNews blog aggregator\', now(), \'ENEWS.WA.blogs_agregator()\', 30)
')
;

ENEWS.WA.exec_no_error('
  insert replacing DB.DBA.SYS_SCHEDULED_EVENT (SE_NAME, SE_START, SE_SQL, SE_INTERVAL)
    values(\'eNews tags aggregator\', now(), \'ENEWS.WA.tags_agregator()\', 10080)
')
;

create procedure ENEWS.WA.tags_procedure (
  in domain_id any,
  in account_id any,
  in item_id any)
{
  declare tag varchar;
  declare tags any;

  result_names (tag);
  tags := ENEWS.WA.tags_account_item_select (domain_id, account_id, item_id);
  tags := split_and_decode (tags, 0, '\0\0,');
  foreach (any tag in tags) do
  	result (trim (tag));
}
;

ENEWS.WA.exec_no_error ('
  drop view ENEWS.WA.TAGS_VIEW
')
;

ENEWS.WA.exec_no_error ('
  create procedure view ENEWS..TAGS_VIEW as ENEWS.WA.tags_procedure (domain_id, account_id, item_id) (EFTV_TAG varchar)
')
;

-------------------------------------------------------------------------------
--
registry_set ('news_index_version', '1');
