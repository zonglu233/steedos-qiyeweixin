# 获取suite_access_token:OK
Qiyeweixin.getSuiteAccessToken = (suite_id, suite_secret, suite_ticket) ->
	try
		data = {
			suite_id:suite_id,
			suite_secret:suite_secret,
			suite_ticket:suite_ticket
		}
		response = HTTP.post(
			"https://qyapi.weixin.qq.com/cgi-bin/service/get_suite_token", 
			{
				data: data,
				headers:"Content-Type": "application/json"
			})
		if response.statusCode != 200
			throw response
		return response.data
	catch err
		console.error err
		throw _.extend(new Error("Failed to complete OAuth handshake with suiteAccessTokenGet. " + err), {response: err});


# 获取预授权码:OK
Qiyeweixin.getPreAuthCode = (suite_id,suite_access_token) ->
	try
		data = {
			suite_id:suite_id
		}
		response = HTTP.post(
			"https://qyapi.weixin.qq.com/cgi-bin/service/get_pre_auth_code?suite_access_token=" + suite_access_token, 
			{
				data: data,
				headers:"Content-Type": "application/json"
			})
		if response.statusCode != 200
			throw response
		return response.data
	catch err
		console.error err
		throw _.extend(new Error("Failed to complete OAuth handshake with suiteAccessTokenGet. " + err), {response: err});

# 获取企业永久授权码
Qiyeweixin.getPermanentCode = (suite_id,auth_code,suite_access_token) ->
	try
		data = {
			suite_id:suite_id,
			auth_code:auth_code
		}
		response = HTTP.post(
			"https://qyapi.weixin.qq.com/cgi-bin/service/get_permanent_code?suite_access_token=" + suite_access_token, 
			{
				data: data,
				headers:"Content-Type": "application/json"
			})
		if response.statusCode != 200
			throw response
		return response.data
	catch err
		console.error err
		throw _.extend(new Error("Failed to complete OAuth handshake with suiteAccessTokenGet. " + err), {response: err});

# 获取access_token
Qiyeweixin.getCorpToken = (suite_id,auth_corpid,permanent_code,suite_access_token) ->
	try
		data = {
			suite_id:suite_id,
			auth_corpid:auth_corpid,
			permanent_code:permanent_code
		}
		response = HTTP.post(
			"https://qyapi.weixin.qq.com/cgi-bin/service/get_corp_token?suite_access_token=" + suite_access_token, 
			{
				data: data,
				headers:"Content-Type": "application/json"
			})
		if response.statusCode != 200
			throw response
		return response.data
	catch err
		console.error err
		throw _.extend(new Error("Failed to complete OAuth handshake with suiteAccessTokenGet. " + err), {response: err});

# 获取部门列表
Qiyeweixin.getDepartmentList =(access_token)->
	try
		getDepartmentListUrl = "https://qyapi.weixin.qq.com/cgi-bin/department/list?access_token=" + access_token
		response = HTTP.get getDepartmentListUrl
		if response.error_code
			console.error err
			throw response.msg
		if response.data.errcode>0 
			throw response.data.errmsg
		return response.data.department
	catch err
		console.error err
		throw _.extend(new Error("Failed to complete OAuth handshake with getDepartmentList. " + err), {response: err});

# 获取部门下用户列表
Qiyeweixin.getUserList =(access_token,department_id)->
	try
		getUserListUrl = "https://qyapi.weixin.qq.com/cgi-bin/user/list?access_token=" + access_token + "&department_id=" + department_id + "&fetch_child=0"
		response = HTTP.get getUserListUrl
		if response.error_code
			console.error err
			throw response.msg
		if response.data.errcode>0 
			throw response.data.errmsg
		return response.data.userlist
	catch err
		console.error err
		throw _.extend(new Error("Failed to complete OAuth handshake with getUserList. " + err), {response: err});

# 获取管理员列表
Qiyeweixin.getAdminList =(auth_corpid,agentid)->
	try
		o = ServiceConfiguration.configurations.findOne({service: "qiyeweixin"})
		data = {
			auth_corpid:auth_corpid,
			agentid:agentid
		}
		response = HTTP.post(
			"https://qyapi.weixin.qq.com/cgi-bin/service/get_admin_list?suite_access_token=" + o.suite_access_token, 
			{
				data: data,
				headers:"Content-Type": "application/json"
			})
		if response.statusCode != 200
			throw response
		return response.data.admin
	catch err
		console.error err
		throw _.extend(new Error("Failed to complete OAuth handshake with suiteAccessTokenGet. " + err), {response: err});

# 通讯录变更
Qiyeweixin.changeContact = (message)->
	switch message.ChangeType
		when 'create_user'
			console.log "create_user"
			us_doc = db.users.findOne({"services.qiyeweixin.id": message.UserID})
			space_id = 'qywx-'+message.AuthCorpId
			if !us_doc
				us_doc = {}
				us_doc.name = message.Name
				us_doc.avatar = message.Avatar
				us_doc.userid = message.UserID				
				us_doc._id = createUser us_doc
				us_doc.department = message?.Department || []
				#更新organization表
				us_doc.department.forEach (dept)->
					dept_id = space_id+'-'+dept
					dept_users = db.organizations.findOne({_id:dept_id}).users
					dept_users.push us_doc._id
					db.organizations.direct.update(dept_id,{$set:{users:dept_users,modified:new Date()}})
				# 更新space_user表
				su = db.space_users.findOne(_id:space_id+us_doc._id)
				if !su
					createSpaceUser us_doc,space_id
		when 'update_user'
			#考虑由于userId也是可修改的，虽然只能修改一次
			up_us = db.users.findOne({"services.qiyeweixin.id": message.UserID})
			if up_us
				u = up_us
				if message.Name
					u.name = message.Name
				if message.Avatar
					u.avatar = message.Avatar
				if message.NewUserID
					u.services.qiyeweixin.id = message.NewUserID
				u.modified = new Date()
				#db.users.direct.update(up_us._id,{$set:{modified:new Date()}})
				db.users.direct.update(up_us._id,{$set:u})
		#可能需要更新space_user表，未完成
				 #updateUser(u,up_us)
			# else
			# 	db.users.direct.insert u
			console.log "update_user"
			# 调用修改成员方法
		when 'delete_user'
			console.log "delete_user"
			dt_us = db.users.findOne({"services.qiyeweixin.id": message.UserID})
			if dt_us
				space_id = 'qywx-'+message.AuthCorpId
				su_id = space_id+dt_us._id
				db.users.direct.remove({_id: dt_us._id})
				db.space_users.direct.remove({_id:su_id})
				#g更新organizations表的users字段
				#.splice，删除数组指定位置的元素
				depts = message?.Department || []
				depts.forEach (dept)->
					dept_id = space_id+'-'+dept
					dept_users = db.organizations.findOne({_id:dept_id}).users
					dept_users.splice(dept_users.indexOf(dt_us._id),1)
					db.organizations.direct.update(dept_id,{$set:{users:dept_users,modified:new Date()}})
			# 调用删除成员方法
		when 'create_party'
			org_doc = db.organizations.findOne({_id:"qywx-" + message.AuthCorpId + "-" + message.Id})
			if !org_doc
				org.id = message.Id
				org.parentid = message.ParentId
				org.name = message.Name
				user_data = []
				space_id = "qywx-" + message.AuthCorpId
				createOrganization org,user_data,space_id
		
		when 'update_party'
			space_id = "qywx-" + message.AuthCorpId
			org_doc = db.organizations.findOne({_id: space_id+ "-" + message.Id})
			if org_doc
				org = {}
				org.id = message.Id
				org.name = message.Name
				org.parentid = message.parentid
				modifyOrg org_doc,org,space_id
		when 'delete_party'
			org_doc = db.organizations.findOne({_id:"qywx-" + message.AuthCorpId + "-" + message.Id})
			if org_doc and !org_doc.children #部门内又成员也不可以删除，但是暂时没做这个判断
				db.organizations.direct.remove(_id:"qywx-" + message.AuthCorpId + "-" + message.Id)
				orgParent = db.organizations.direct.findOne(_id:'qywx-'+message.AuthCorpId + "-" + message.ParentId)
				children = orgParent?.children || []
				children.splice(children.indexOf(org_doc._id),1)
				db.organizations.direct.update({_id:'qywx-'+message.AuthCorpId + "-" + message.ParentId},{$set:{children:children,modified:new Date()}})
			console.log "delete_party"
			# 调用删除部门方法
		when 'update_tag'
			console.log "update_tag"
			# 调用修改标签方法
# 初始化公司
Qiyeweixin.initCompany = (auth_corp_info,auth_info)->
## 命名规则与钉钉保持一致
	console.log "============企业相关数据==============="
	console.log auth_corp_info
## 初始化，先把工作区中所有的都清空，包括space、user、organizations、space_user这几个表
	space_id = auth_corp_info.space_id
	# 删除user
	# 根据查询到的space_user数据，删除user表中数据
	delete_users = []
	delete_users = db.space_users.find({space:space_id},fields: {user:1})
	delete_users.forEach (delete_user)->
		db.users.direct.remove({_id: delete_user.user})
	# 删除space_user
	db.space_users.direct.remove({space:space_id})
	# 删除organization
	db.organizations.direct.remove({space:space_id})
	# 删除space
	db.spaces.direct.remove({_id: space_id})

## 新增数据，space、user、organizations、space_user这几个表
	# 首先找出owner
	admins = []
	space_admin_data = Qiyeweixin.getAdminList auth_corp_info.corpid,auth_info.agent[0].agentid
	space_admin_data.forEach (admin)->
		if admin.auth_type
			admin_user = db.users.findOne({"services.qiyeweixin.id": admin.userid})
			if admin_user
				admins.push admin_user._id
	auth_corp_info.owner = admins[0]
	auth_corp_info.admins = admins

	# space表，初始化新工作区
	s_doc = db.space.findOne({_id:auth_corp_info.space_id})
	if !s_doc
		createSpace auth_corp_info
	# 组织架构，获取部门列表
	org_data = Qiyeweixin.getDepartmentList auth_corp_info.access_token
	# 根据部门获取成员信息
	org_data.forEach (org)->
		user_data = Qiyeweixin.getUserList auth_corp_info.access_token,org.id
		# 循环每个成员
		orgusers = []
		user_data.forEach (u)->
			# user表，创建新用户
			user_id = createUser u
			user = {}
			user._id = user_id
			orgusers.push user_id
			user.name = u.name
			user.department = u.department
			
			# space_user表
			su = db.space_users.findOne(_id:space_id+user_id)
			if !su
				createSpaceUser user,space_id
		# organizations表，新增
		org_doc = db.organizations.findOne({_id:space_id + "-" + org.id})
		if !org_doc
			createOrganization org,orgusers,space_id

# 调用新增部门方法
createOrganization = (org,orgusers,space_id)->
	org_doc = {}
	orgparent = {}
	org_doc._id = space_id + "-" + org.id
	org_doc.name = org.name
	org_doc.fullname =org.name
	if org.parentid >= 1
		orgparent = db.organizations.findOne(_id:space_id + "-" + org.parentid)
		if orgparent
			org_doc.parent = orgparent._id
			org_doc.fullname = orgparent.calculateFullname()+"/"+org.name
	org_doc.sort_no = 100
	org_doc.created = new Date()
	org_doc.modified = new Date()
	# org_doc.created_by = 下一步
	# org_doc.modified_by = 
	if org.id == 1
		org_doc.is_company = true
	org_doc.space = space_id
	org_doc.users = orgusers
	db.organizations.direct.insert org_doc
	children = orgparent?.children || {}
	children.push org_doc._id
	db.organizations.direct.update({_id:orgparent._id},{$set:{children:children,modified:new Date()}})
#调用新增space-user记录方法
createSpaceUser = (user,space_id)->
	su_doc = {}
	su_doc._id = space_id+user._id #_id = 工作区id+用户id
	su_doc.name = user.name
	su_doc.email = user._id
	su_doc.space = space_id
	su_doc.position = user.position
	su_doc.organizations = []
	user?.department.forEach (department)->
		su_doc.organizations.push space_id + "-" + department  #部门id = space_id + 部门号
	su_doc.organization = su_doc.organizations[0]
	su_doc.user_accepted = true
	su_doc.modified = new Date()
	su_doc.created = new Date()
	db.space_users.direct.insert su_doc
#新增工作区	
createSpace = (auth_corp_info)->
	s_doc = {}
	s_doc._id = auth_corp_info.space_id
	s_doc.name = auth_corp_info.corp_name
	s_doc.owner = auth_corp_info.owner
	s_doc.admins = auth_corp_info.admins
	s_doc.is_deleted = false
	s_doc.created = new Date
	s_doc.created_by = auth_corp_info.owner
	s_doc.modified = new Date
	s_doc.modified_by = auth_corp_info.owner
	s_doc.services = { qiyeweixin:{ corp_id: auth_corp_info.corpid, access_token: auth_corp_info.access_token, permanent_code: auth_corp_info.permanent_code}}
	space_id = db.spaces.direct.insert(s_doc)

# 创建用户方法
createUser = (user)->
	doc = {}
	doc._id = db.users._makeNewID()
	doc.steedos_id = doc._id
	doc.email = user.userid
	doc.name = user.name
	doc.locale = "zh-cn"
	doc.is_deleted = false
	doc.created = new Date
	doc.modified = new Date
	doc.services = {qiyeweixin:{id: user.userid}}
	doc.avatarURL = user.avatar
	user_id = db.users.direct.insert(doc)
	return user_id



modifySpace = (old_space,new_space)->
	s_doc = {}
	if old_space.name != new_space.corp_name
		s_doc.name = new_space.corp_name
	if old_space.owner != new_space.owner
		s_doc.owner = new_space.owner
	if old_space.admins.sort().toString() != new_space.admins.sort().toString()
		s_doc.admins = new_space.admins
	if s_doc.hasOwnProperty('name') || s_doc.hasOwnProperty('owner') || s_doc.hasOwnProperty('admins')
		s_doc.modified = new Date
		s_doc.modified_by = new_space.owner
		s_qywx = old_space.services.qiyeweixin
		s_qywx.access_token = new_space.access_token
		s_qywx.permanent_code = new_space.permanent_code
		s_doc['services.qiyeweixin'] = s_qywx
		db.spaces.direct.update(old_space._id, {$set: s_doc})
# 修改用户方法(授权企业初始化时候使用的更新用户方法)
modifyUser = (old_user,new_user)->
	doc = {}
	if old_user.name != new_user.name
		doc.name = new_user.name
	if old_user.avatarURL != new_user.avatar
		doc.avatarURL = new_user.avatar
	if old_user.userid != new_user.userid
		doc.services = {qiyeweixin:{id: new_user.userid}}
	if doc.hasOwnProperty('name') || doc.hasOwnProperty('avatar') || doc.hasOwnProperty('is_deleted')
		doc.modified = new Date()
		db.users.direct.update old_user._id, {$set: doc}
		#更新space_user表
		db.space_users.direct.update({user:old_user._id},{$set:{name:doc.name,modified:new Date()}})
#修改部门
modifyOrg = (old_org,new_org,space_id)->
	doc = {}
	if old_org.name != new_org.name
		doc.name = new_org.name
	if new_org.parentid>=1
		doc.parent =space_id+'_'+new_org.parentid
		doc.fullname = db.organizations.findOne({_id:doc.parent}).calculateFullname()+"/"+doc.name
	if old_org.hasOwnProperty('name') || old_org.hasOwnProperty('parent')
		doc.modified = new Date()
		# org_doc.modified_by = owner_id
		db.organizations.direct.update(old_org._id, {$set: doc})
		org_doc.children?.forEach (children_org)->
			fullname = new_org.calculateFullname()+'/'+children_org.name
			db.organizations.direct.update({_id:children_org},{$set:{fullname:fullname,modified:new Date()}})
	console.log "update_party"
			# 调用修改部门方法














