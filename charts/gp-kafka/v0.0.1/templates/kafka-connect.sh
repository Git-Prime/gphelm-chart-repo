#!/bin/sh

    echo "**** Installing prerequisites ****"
    apt update; apt -y install kafkacat curl

    echo "**** **************************** ****"
    echo "**** Registering kafka connectors ****"
    echo "**** **************************** ****"

    curl -X PUT {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors/jdbc_source_postgres_org_bulk/config -H "Content-Type: application/json" -d '{
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "source_data_organization",
      "numeric.mapping": "best_fit",
      "query":"select id, name slug, state, trial_expires_at, is_paid, stripe_customer_id, team_size, advanced_scope_depth, fork_improvements_enabled from core_organization",
      "mode":"incrementing", "incrementing.column.name": "id",
      "validate.non.null": false,
      "poll.interval.ms" : {{ .Values.etlSourceDatabase.incrementingPollIntervalMS }}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "work-event-init",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "table.name.format": "work_event_tmp",
      "insert.mode":"insert",
      "pk.mode":"none",
      "fields.whitelist":"org_id,apex_user_id,repo_id,xsize,message",
      "topics": "source_data_commits_",
      "auto.create":false,
      "auto.evolve":false}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "work-event-search-init",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSinkConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "table.name.format": "work_event_search_tmp",
      "insert.mode":"insert",
      "pk.mode":"none",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"orgId:org_id,searchLookupSha:search_lookup_sha,searchTsvector:search_tsvector",
      "fields.whitelist":"org_id,search_lookup_sha,search_tsvector",
      "topics": "work_event_search_init",
      "auto.create":false,
      "auto.evolve":false}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "scm-commits",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "source_data_commits_",
      "mode":"timestamp",
      "timestamp.column.name":"audit_created_at",
      "query":"select a.id, a.audit_created_at, a.hexsha, a.author_date, a.author_local_date, a.is_merge, a.haloc, a.new_work, a.legacy_refactor, a.help_others, a.churn, a.files, a.hunks, a.insertions, a.deletions, a.ins_del_ratio, a.levenshtein, a.risk, a.impact, a.is_trivial, a.committer_date, a.is_pr_orphan, a.is_outlier, a.multi_line_comments, a.single_line_comments, a.logical_code, a.whitespace_and_punctuation, a.author_tzoffset, a.committer_tzoffset, a.ignore_hash, a.user_alias_id, a.org_id, a.outlier_reason_id, a.repo_id, a.message_id, b.message from scm_commit a inner join scm_commit_message b on a.message_id = b.id and a.org_id = b.org_id",
      "numeric.mapping":"best_fit",
      "quote.sql.identifiers":"never",
      "table.types":"VIEW",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"audit_created_at:auditCreatedAt, author_date:authorDate, author_local_date:authorLocalDate, is_merge:isMerge, new_work:newWork, legacy_refactor:legacyRefactor, help_others:helpOthers, ins_del_ratio:insDelRatio, is_trivial:isTrivial, committer_date:committerDate, is_pr_orphan:isPrOrphan, is_outlier:isOutlier, multi_line_comments:multiLineComments, single_line_comments:singleLineComments, logical_code:logicalCode, whitespace_and_punctuation:whitespaceAndPunctuation, author_tzoffset:authorTzoffset, committer_tzoffset:committerTzoffset, ignore_hash:ignoreHash, user_alias_id:userAliasId, org_id:orgId, outlier_reason_id:outlierReasonId, repo_id:repoId, message_id:messageId",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":120000}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "scm-ticketComments",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "ticketComments",
      "mode":"timestamp",
      "timestamp.column.name":"audit_created_at",
      "query":"select a.id, a.ticket_comment_external_ident, a.created_at, a.updated_at, a.audit_created_at, a.user_alias_id, a.ticket_id, a.word_count, a.body_id, b.ticket_comment_body from event_ticket_comment a left join event_ticket_comment_body b on a.body_id = b.id ",
      "numeric.mapping":"best_fit",
      "quote.sql.identifiers":"never",
      "table.types":"VIEW",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"ticket_comment_external_ident:ticketCommentExternalIdent, created_at:createdAt, updated_at:updatedAt, audit_created_at:auditCreatedAt, user_alias_id:userAliasId, ticket_id:ticketId, word_count:wordCount, body_id:bodyId, ticket_comment_body:ticketCommentBody",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":120000}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "scm-tickets",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "tickets",
      "mode":"timestamp",
      "timestamp.column.name":"audit_created_at",
      "query":"select a.id, a.title_id, a.body_id, a.org_id, a.vendor_id, a.state_id, a.project_id, a.created_by_id, a.closed_by_id, a.comment_count, a.created_at, a.updated_at, a.closed_at, a.audit_created_at, a.ticket_ident, a.ticket_external_ident, a.url, a.type, a.parent_ticket_ident, b.ticket_body from event_ticket a left join event_ticket_body b on a.body_id = b.id ",
      "numeric.mapping":"best_fit",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"title_id:titleId, body_id:bodyId, org_id:orgId, vendor_id:vendorId, state_id:stateId, project_id:projectId, created_by_id:createdById, closed_by_id:closedById, comment_count:commentCount, created_at:createdAt, updated_at:updatedAt, closed_at:closedAt, audit_created_at:auditCreatedAt, ticket_ident:ticketIdent, ticket_external_ident:ticketExternalIdent, parent_ticket_ident:parentTicketIdent, b.ticket_body:ticketBody",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":120000}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "scm-ticketEvents",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "ticketEvents",
      "mode":"timestamp",
      "timestamp.column.name":"audit_created_at",
      "query":"select a.id, a.ticket_id, a.user_alias_id, a.user_alias2_id, a.ticket_event_type_id, a.created_at, a.audit_created_at, a.params, a.ticket_event_external_ident, b.ticket_event_type from event_ticket_event a left join event_ticket_event_type b on a.ticket_event_type_id = b.id ",
      "numeric.mapping":"best_fit",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"ticket_id:ticketId, user_alias_id:userAliasId, user_alias2_id:userAlias2Id, ticket_event_type_id:ticketEventTypeId, created_at:createdAt, audit_created_at:auditCreatedAt, ticket_event_external_ident:ticketEventExternalIdent, ticket_event_type:ticketEventType",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":120000}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "workevent-project_type",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "source_data_project_type_",
      "mode":"bulk",
      "query":"select id, name, audit_created_at from project_type",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"audit_created_at:auditCreatedAt",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":86400000}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "workevent-work_event_search",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "source_data_work_event_search_",
      "mode":"bulk",
      "query":"select id, org_id, search_lookup_sha, audit_created_at from work_event_search",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"org_id:orgId, search_lookup_sha:searchLookupSha, audit_created_at:auditCreatedAt",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":86400000}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "workevent-work_event_primary_occurrence",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "workEventOccurrence",
      "mode":"timestamp",
      "timestamp.column.name":"audit_created_at",
      "query":"select id, work_event_id, audit_created_at from work_event_occurrence",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"work_event_id:workEventId, audit_created_at:auditCreatedAt",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":60000}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "workevent-work_event_type",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "source_data_work_event_type_",
      "mode":"bulk",
      "query":"select id, name, audit_created_at from work_event_type",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"audit_created_at:auditCreatedAt",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":86400000}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "workeventExtended",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "workevent",
      "mode":"timestamp",
      "timestamp.column.name":"audit_created_at",
      "query":"select id, org_id, apex_user_id, event_type_id, event_ts, audit_created_at, event_lookup_sha, work_event_search_id from work_event",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"org_id:orgId, apex_user_id:apexUserId, event_type_id:eventTypeId, event_ts:eventTs, audit_created_at:auditCreatedAt, event_lookup_sha:eventLookupSha, work_event_search_id:workEventSearchId",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":120000}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "workeventExtended",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "workeventExtended",
      "mode":"timestamp",
      "timestamp.column.name":"a.audit_created_at",
      "query":"select a.audit_created_at, a.id, a.org_id, a.apex_user_id, a.event_type_id, a.event_ts, a.event_lookup_sha, a.work_event_search_id, b.search_lookup_sha from work_event a left join work_event_search b on a.work_event_search_id = b.id",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"org_id:orgId, apex_user_id:apexUserId, event_type_id:eventTypeId, event_ts:eventTs, audit_created_at:auditCreatedAt, event_lookup_sha:eventLookupSha, work_event_search_id:workEventSearchId, search_lookup_sha:searchLookupSha",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":120000}
    }'

    curl -X POST {{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "workevent-orphan_state",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "source_data_orphan_state_",
      "mode":"bulk",
      "query":"select id, name, audit_created_at from orphan_state",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"audit_created_at:auditCreatedAt",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":86400000}
    }'

    curl -X POST h{{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "scm-pullRequests",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "pullRequests",
      "mode":"timestamp",
      "timestamp.column.name":"audit_created_at",
      "query":"select a.id, a.org_id, a.project_id, a.title_id, a.body_id, a.vendor_id, a.state_id, a.created_by_id, a.merged_by_id, a.closed_by_id, a.additions, a.deletions, a.enrich_tries, a.created_at, a.updated_at, a.closed_at, a.audit_created_at, a.enriched_at, a.metrics_complete, a.pr_ident, a.pr_external_ident, a.url, a.merge_hexsha_id, b.pr_body from scm_pr a left join scm_pr_body b on a.body_id = b.id ",
      "numeric.mapping":"best_fit",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"org_id:orgId, project_id:projectId, title_id:titleId, body_id:bodyId, vendor_id:vendorId, state_id:stateId, created_by_id:createdById, merged_by_id:mergedById, closed_by_id:closedById, enrich_tries:enrichTries, created_at:createdAt, updated_at:updatedAt, closed_at:closedAt, audit_created_at:auditCreatedAt, enriched_at:enrichedAt, metrics_complete:metricsComplete, pr_ident:prIdent, pr_external_ident:prExternalIdent, merge_hexsha_id:mergeHexshaId, pr_body:prBody",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":120000}
    }'

    curl -X POST h{{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "scm-prEvents",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "prEvents",
      "mode":"timestamp",
      "timestamp.column.name":"audit_created_at",
      "query":"select a.id, a.user_alias_id, a.user_alias2_id, a.pr_id, a.created_at, a.audit_created_at, a.pr_event_type_id, a.pr_event_external_ident, a.params, b.pr_event_type from scm_pr_event a left join scm_pr_event_type b on a.pr_event_type_id = b.id ",
      "numeric.mapping":"best_fit",
      "quote.sql.identifiers":"never",
      "table.types":"TABLE",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"user_alias_id:userAliasId, user_alias2_id:userAlias2Id, pr_id:prId, created_at:createdAt, audit_created_at:auditCreatedAt, pr_event_type_id:prEventTypeId, pr_event_external_ident:prEventExternalIdent, pr_event_type:prEventType",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":120000}
    }'

    curl -X POST h{{ .Values.kafkaConnect.host }}:{{ .Values.kafkaConnect.nodePort }}/connectors -H "Content-Type: application/json" -d '{
      "name": "scm-prComments",
      "config": {
      "connector.class": "io.confluent.connect.jdbc.JdbcSourceConnector",
      "connection.url": "jdbc:postgresql://{{ .Values.etlSourceDatabase.host }}:{{ .Values.etlSourceDatabase.port }}/{{ .Values.etlSourceDatabase.name }}",
      "connection.user": "{{ .Values.etlSourceDatabase.user }}",
      "connection.password": "{{ .Values.etlSourceDatabase.pw }}",
      "topic.prefix": "prComments",
      "mode":"timestamp",
      "timestamp.column.name":"audit_created_at",
      "query":"select a.id, pr_id, a.parent_id, a.user_alias_id, a.reaction_time, a.word_count, a.commit_reaction_by_id, a.commit_reaction_time, a.comment_type_id, a.in_reply_to_id, a.url, a.pr_comment_external_ident, a.created_at, a.audit_created_at, a.is_extension_comment, a.body_id, b.pr_comment_body from scm_pr_comment a left join scm_pr_comment_body b on a.body_id = b.id ",
      "numeric.mapping":"best_fit",
      "quote.sql.identifiers":"never",
      "table.types":"VIEW",
      "transforms":"RenameField",
      "transforms.RenameField.type":"org.apache.kafka.connect.transforms.ReplaceField$Value",
      "transforms.RenameField.renames":"pr_id:prId, a.parent_id:parentId, a.user_alias_id:userAliasId, a.reaction_time:reactionTime, a.word_count:wordCount, a.commit_reaction_by_id:commitReactionById, a.commit_reaction_time:commitReactionTime, a.comment_type_id:commentTypeId, a.in_reply_to_id:inReplyToId, a.pr_comment_external_ident:prCommentExternalIdent, a.created_at:createdAt, a.audit_created_at:auditCreatedAt, a.is_extension_comment:isExtensionComment, a.body_id:bodyId, b.pr_comment_body:prCommentBody",
      "errors.tolerance":"all",
      "validate.non.null": false,
      "poll.interval.ms":120000}
    }'