create or replace package auditor authid definer as

  function get_audit_id return number;

  function get_data(p_value in anydata) return varchar2;
  
  function generate_audit_trigger(p_table_owner in varchar2, p_table_name in varchar2, p_trigger_name in varchar2 default null) return clob;
  
  function to_anydata(p_value in number) return anydata;
  function to_anydata(p_value in varchar2) return anydata;
  function to_anydata(p_value in date) return anydata;
  function to_anydata(p_value in timestamp) return anydata;
  function to_anydata(p_value in timestamp with time zone) return anydata;
  function to_anydata(p_value in timestamp with local time zone) return anydata;
  function to_anydata(p_value in interval day to second) return anydata;
  function to_anydata(p_value in interval year to month) return anydata;
  
  --function equals(p_old_value in number, p_new_value in number) return boolean;
  --function equals(p_old_value in varchar2, p_new_value in varchar2) return boolean;
  --function equals(p_old_value in date, p_new_value in date) return boolean;
  --function equals(p_old_value in timestamp, p_new_value in timestamp) return boolean;
  --function equals(p_old_value in timestamp with time zone, p_new_value in timestamp with time zone) return boolean;
  --function equals(p_old_value in timestamp with local time zone, p_new_value in timestamp with local time zone) return boolean;
  --function equals(p_old_value in anydata, p_new_value in anydata) return boolean;

  
  procedure start_audit(
    p_table_owner       in varchar2, 
    p_table_name        in varchar2, 
    p_table_key         in varchar2 default null,
    p_exclude_columns   in clob default null
  );
  
  procedure stop_audit(
    p_table_owner       in varchar2, 
    p_table_name        in varchar2
  );
  
  procedure refresh_audit(
    p_table_owner       in varchar2, 
    p_table_name        in varchar2
  );
  
  procedure audit_row(
    p_audit_id    in number, 
    p_table_owner in varchar2,
    p_table_name  in varchar2,
    p_row_key     in anydata,
    p_column_name in varchar2, 
    p_old_value   in anydata,
    p_new_value   in anydata
  );
  
end;
/

create or replace package body auditor as

  NEW_LINE                constant char(1)      := chr(10);
  
  
  function to_anydata(p_value in number) return anydata
  is
  begin
    return anydata.convertNumber(p_value);
  end;
  
  function to_anydata(p_value in varchar2) return anydata
  is
  begin
    return anydata.convertVarchar2(p_value);
  end;
  
  function to_anydata(p_value in date) return anydata
  is
  begin
    return anydata.convertDate(p_value);
  end;
  
  function to_anydata(p_value in timestamp) return anydata
  is
  begin
    return anydata.convertTimestamp(p_value);
  end;
  
  function to_anydata(p_value in timestamp with time zone) return anydata
  is
  begin
    return anydata.convertTimestampTZ(p_value);
  end;
  
  function to_anydata(p_value in timestamp with local time zone) return anydata
  is
  begin
    return anydata.convertTimestampLTZ(p_value);
  end;
  
  function to_anydata(p_value in interval day to second) return anydata
  is
  begin
    return anydata.convertIntervalDS(p_value);
  end;
    
  function to_anydata(p_value in interval year to month) return anydata
  is
  begin
    return anydata.convertIntervalYM(p_value);
  end;
  
  
  function equals(p_old_value in number, p_new_value in number) return boolean
  is
  begin
    return ((p_old_value is not null and p_new_value is not null and p_old_value = p_new_value) 
         or (p_old_value is null and p_new_value is null)
    );
  end;
  
  function equals(p_old_value in varchar2, p_new_value in varchar2) return boolean
  is
  begin
    return ((p_old_value is not null and p_new_value is not null and p_old_value = p_new_value) 
         or (p_old_value is null and p_new_value is null)
    );
  end;
  
  function equals(p_old_value in date, p_new_value in date) return boolean
  is
  begin
    return ((p_old_value is not null and p_new_value is not null and p_old_value = p_new_value) 
         or (p_old_value is null and p_new_value is null)
    );
  end;
  
  function equals(p_old_value in timestamp, p_new_value in timestamp) return boolean
  is
  begin
    return ((p_old_value is not null and p_new_value is not null and p_old_value = p_new_value) 
         or (p_old_value is null and p_new_value is null)
    );
  end;
  
  function equals(p_old_value in timestamp with time zone, p_new_value in timestamp with time zone) return boolean
  is
  begin
    return ((p_old_value is not null and p_new_value is not null and p_old_value = p_new_value) 
         or (p_old_value is null and p_new_value is null)
    );
  end;
  
  function equals(p_old_value in timestamp with local time zone, p_new_value in timestamp with local time zone) return boolean
  is
  begin
    return ((p_old_value is not null and p_new_value is not null and p_old_value = p_new_value) 
         or (p_old_value is null and p_new_value is null)
    );
  end;
  
  function equals(p_old_value in interval day to second, p_new_value in interval day to second) return boolean
  is
  begin
    return ((p_old_value is not null and p_new_value is not null and p_old_value = p_new_value) 
         or (p_old_value is null and p_new_value is null)
    );
  end;
  
  function equals(p_old_value in interval year to month, p_new_value in interval year to month) return boolean
  is
  begin
    return ((p_old_value is not null and p_new_value is not null and p_old_value = p_new_value) 
         or (p_old_value is null and p_new_value is null)
    );
  end;
  
  function equals(p_old_value in anydata, p_new_value in anydata) return boolean
  is
    v_equals boolean;
  begin
    case anydata.GetTypeName(p_old_value)
      when 'SYS.NUMBER' then 
        v_equals := equals(anydata.AccessNumber(p_old_value), anydata.AccessNumber(p_new_value));
      when 'SYS.DATE' then 
        v_equals := equals(anydata.AccessDate(p_old_value), anydata.AccessDate(p_new_value));
      when 'SYS.CHAR' then 
        v_equals := equals(anydata.AccessChar(p_old_value), anydata.AccessChar(p_new_value));
      when 'SYS.VARCHAR2' then 
        v_equals := equals(anydata.AccessVarchar2(p_old_value), anydata.AccessVarchar2(p_new_value));
      when 'SYS.TIMESTAMP' then 
        v_equals := equals(anydata.AccessTimestamp(p_old_value), anydata.AccessTimestamp(p_new_value));
      when 'SYS.TIMESTAMP_WITH_TIMEZONE' then
        v_equals := equals(anydata.AccessTimestampTZ(p_old_value), anydata.AccessTimestampTZ(p_new_value));
      when 'SYS.TIMESTAMP_WITH_LTZ' then
        v_equals := equals(anydata.AccessTimestampLTZ(p_old_value), anydata.AccessTimestampLTZ(p_new_value));
      when 'SYS.INTERVAL_DAY_SECOND' then
        v_equals := equals(anydata.AccessIntervalDS(p_old_value), anydata.AccessIntervalDS(p_new_value));
      when 'SYS.INTERVAL_YEAR_MONTH' then
        v_equals := equals(anydata.AccessIntervalYM(p_old_value), anydata.AccessIntervalYM(p_new_value));
      else 
        raise_application_error(-20000, 'Data type not supported!');
    end case;
    
    return v_equals;
  end;


  function get_log_info return varchar2
  is
  begin
    return '***** Log info *****'||NEW_LINE
      ||'session_user : '||sys_context('userenv', 'session_user')||NEW_LINE
      ||'sid          : '||sys_context('userenv', 'sid')||NEW_LINE
      ||'module       : '||sys_context('userenv', 'module')||NEW_LINE
      ||'action       : '||sys_context('userenv', 'action')||NEW_LINE
      ||'host         : '||sys_context('userenv', 'host')||NEW_LINE
      ||'os_user      : '||sys_context('userenv', 'os_user');
  end;


  function get_call_stack return varchar2
  is
  begin
    return dbms_utility.format_call_stack;
  end;
  
  
  function get_audit_id return number
  is
  begin
    return seq_auditor_logs.nextval;
  end;
  
  
  function get_data(p_value in anydata) return varchar2
  is
    v_return varchar2(4000);
  begin
    case anydata.getTypeName(p_value) 
      when 'SYS.VARCHAR2' then 
        v_return := anydata.accessVarchar2(p_value);
      when 'SYS.CHAR' then 
        v_return := anydata.accessChar(p_value);
      when 'SYS.NUMBER' then
        v_return := to_char(anydata.accessNumber(p_value));
      when 'SYS.DATE' then 
        v_return := to_char(anydata.accessDate(p_value));
      when 'SYS.TIMESTAMP' then 
        v_return := to_char(anydata.accessTimestamp(p_value));
      when 'SYS.TIMESTAMP_WITH_TIMEZONE' then
        v_return := to_char(anydata.accessTimestampTZ(p_value));
      when 'SYS.TIMESTAMP_WITH_LTZ' then
        v_return := to_char(anydata.accessTimestampLTZ(p_value));
       when 'SYS.INTERVAL_DAY_SECOND' then
        v_return := to_char(anydata.accessIntervalDS(p_value));
      when 'SYS.INTERVAL_YEAR_MONTH' then
        v_return := to_char(anydata.accessIntervalYM(p_value));
      else 
        v_return := '*** unknown/unsupported ***';
    end case;
    
    return v_return;
  end;
  
  
  function generate_trigger_name(p_table_owner in varchar2, p_table_name in varchar2) return varchar2
  is
    v_object_id number;
  begin
    select object_id
    into v_object_id
    from all_objects
    where object_type = 'TABLE'
    and owner = upper(p_table_owner)
    and object_name = upper(p_table_name);
    
    return 'AUD$'||v_object_id;
  end;
  

  function generate_audit_trigger(p_table_owner in varchar2, p_table_name in varchar2, p_trigger_name in varchar2 default null) return clob
  is
    v_columns   clob;
    v_object_id number;
    v_table_key varchar2(30);
    v_trigger_name varchar2(30);
  begin
    select table_key
    into v_table_key
    from auditor_configs
    where table_owner = upper(p_table_owner)
    and table_name = upper(p_table_name);
  
    select listagg(
'  auditor.audit_row(
     p_audit_id    => v_id,
     p_table_owner => '''||p_table_owner||''',
     p_table_name  => '''||p_table_name||''',
     p_row_key     => auditor.to_anydata(:old.'||v_table_key||'),
     p_column_name => '''||column_name||''',
     p_old_value   => auditor.to_anydata(:old.'||column_name||'),
     p_new_value   => auditor.to_anydata(:new.'||column_name||')
  );', chr(10)) within group (order by column_id) 
    into v_columns
    from all_tab_columns t
    where owner = upper(p_table_owner)
    and table_name = upper(p_table_name)
    and column_name not in (
      select to_char(regexp_substr(table_key||nvl2(exclude_columns, ','||exclude_columns, ''), '[^, ]+', 1, level)) as column_name
      from auditor_configs
      where table_owner = upper(p_table_owner)
      and table_name = upper(p_table_name)
      connect by level <= regexp_count(table_key||nvl2(exclude_columns, ','||exclude_columns, ''), '[A-Z_0-9]+')
    );
    
    v_trigger_name := upper(p_trigger_name);
    if v_trigger_name is null then
      v_trigger_name := generate_trigger_name(
        p_table_owner  => p_table_owner, 
        p_table_name   => p_table_name
      );
    end if;
    
    return 
'create or replace trigger '||v_trigger_name||' 
before update on '||upper(p_table_owner)||'.'||upper(p_table_name)||' 
for each row 
declare
  v_id number;
begin
  v_id := auditor.get_audit_id();
'||v_columns||'
end;';
  end;
  
  
  procedure start_audit(
    p_table_owner       in varchar2, 
    p_table_name        in varchar2,
    p_table_key         in varchar2,
    p_exclude_columns   in clob default null
  )
  is
    v_trigger_name varchar2(30);
    v_trigger      clob;
    v_table_key    varchar2(30);
  begin
    v_trigger_name := generate_trigger_name(
      p_table_owner  => p_table_owner, 
      p_table_name   => p_table_name
    );
    
    v_table_key := upper(p_table_key);
    if v_table_key is null then
    begin
      select cols.column_name
      into v_table_key
      from (
        select row_number() over (order by decode(cons.constraint_type, 'P', 0, 'U', 1, 2)) as rnum, idx.index_name, idx.table_name, idx.owner
        from all_indexes idx
        left join all_constraints cons on cons.owner = idx.table_owner and cons.table_name = idx.table_name
        where idx.uniqueness = 'UNIQUE' 
        and idx.table_owner = 'GLEIDSON'
        and idx.table_name = 'TESTE'
      ) idx 
      join all_ind_columns cols on idx.owner = cols.index_owner and idx.table_name = cols.table_name and idx.index_name = cols.index_name 
      where idx.rnum = 1;
    exception 
      when no_data_found then
        raise_application_error(-20000, 'Table does not have primary key or unique index/constraint!'); 
      when too_many_rows then
        raise_application_error(-20000, 'There is no support for multi-column keys yet');
    end;
    end if;
    
    begin
      insert into auditor_configs (table_owner, table_name, table_key, exclude_columns, trigger_name, enabled, start_audit)
      values (upper(p_table_owner), upper(p_table_name), v_table_key, upper(p_exclude_columns), v_trigger_name, 'Y', current_timestamp);
    exception when dup_val_on_index then
      update auditor_configs 
      set enabled         = 'Y',
          table_key       = v_table_key,
          exclude_columns = upper(p_exclude_columns), 
          trigger_name    = v_trigger_name,
          start_audit     = current_timestamp
      where table_owner = upper(p_table_owner)
      and table_name = upper(p_table_name);
    end;
    
    v_trigger := generate_audit_trigger(
      p_table_owner  => p_table_owner, 
      p_table_name   => p_table_name, 
      p_trigger_name => v_trigger_name
    );
      
    execute immediate v_trigger;
  end;
  
  
  procedure stop_audit(
    p_table_owner       in varchar2, 
    p_table_name        in varchar2
  )
  is
    v_trigger_name varchar2(30);
  begin
    select trigger_name
    into v_trigger_name
    from auditor_configs
    where table_owner = upper(p_table_owner)
    and table_name = upper(p_table_name);
    
    update auditor_configs
    set enabled    = 'N',
        stop_audit = current_timestamp 
    where table_owner = upper(p_table_owner)
    and table_name = upper(p_table_name);
      
    execute immediate 'alter trigger '||v_trigger_name||' disable';
  exception when no_data_found then
    null;
  end;
  
  
  procedure refresh_audit(
    p_table_owner       in varchar2, 
    p_table_name        in varchar2
  )
  is
    v_trigger_name varchar2(30);
    v_trigger      clob;
    v_enabled      char(1);
  begin
    select trigger_name, upper(enabled)
    into v_trigger_name, v_enabled
    from auditor_configs
    where table_owner = upper(p_table_owner)
    and table_name = upper(p_table_name);
    
    v_trigger := generate_audit_trigger(
      p_table_owner  => p_table_owner, 
      p_table_name   => p_table_name, 
      p_trigger_name => v_trigger_name
    );
      
    execute immediate v_trigger;
    
    if v_enabled <> 'Y' then
      execute immediate 'alter trigger '||v_trigger_name||' disable';
    end if;
  end;
  
  
  procedure insert_audit_log(
    p_audit_id    in number,
    p_table_owner in varchar2,
    p_table_name  in varchar2,
    p_row_key     in anydata,
    p_column_name in varchar2,
    p_old_value   in anydata,
    p_new_value   in anydata
  )
  is
    v_log_info    varchar2(500);
    v_call_stack  varchar2(4000);
  begin
    v_log_info   := get_log_info();
    v_call_stack := get_call_stack();
    
    insert into auditor_logs(
      audit_id, 
      audit_date, 
      table_owner, 
      table_name, 
      row_key,
      column_name, 
      old_value, 
      new_value,
      -- 
      audit_callstack,
      audit_info
    ) values (
      p_audit_id, 
      current_timestamp, 
      upper(p_table_owner), 
      upper(p_table_name), 
      p_row_key,
      upper(p_column_name), 
      p_old_value, 
      p_new_value,
      -- 
      v_call_stack,
      v_log_info
    );
  end;
  
  
  procedure audit_row(
    p_audit_id    in number, 
    p_table_owner in varchar2, 
    p_table_name  in varchar2, 
    p_row_key     in anydata,
    p_column_name in varchar2, 
    p_old_value   in anydata, 
    p_new_value   in anydata
  ) 
  is
  begin
    if not equals(p_old_value, p_new_value) then
      insert_audit_log(
        p_audit_id    => p_audit_id,
        p_table_owner => p_table_owner,
        p_table_name  => p_table_name,
        p_row_key     => p_row_key,
        p_column_name => p_column_name,
        p_old_value   => p_old_value,
        p_new_value   => p_new_value
      );    
    end if;
  end;
  
end;
/