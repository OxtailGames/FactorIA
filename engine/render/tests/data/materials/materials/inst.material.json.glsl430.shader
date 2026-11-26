{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "f75e5e0880dc820037ae0c93c059e5f4f012f6ae7d85cbb082650e666c2ae84b",
  "slang": "glsl430",
  "params": [
    "boost"
  ],
  "textures": [],
  "instanced": [
    {
      "name": "raise",
      "vec4": 0,
      "offset": 0,
      "components": 1
    },
    {
      "name": "tint",
      "vec4": 1,
      "offset": 0,
      "components": 4
    }
  ],
  "instanceVec4": 2,
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4825[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1601 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1608;\n    if (!_1601)\n    {\n        _1608 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1608 = _1601;\n    }\n    bool _1616;\n    if (!_1608)\n    {\n        _1616 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1616 = _1608;\n    }\n    bool _1623;\n    if (!_1616)\n    {\n        _1623 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1623 = _1616;\n    }\n    bool _1630;\n    if (!_1623)\n    {\n        _1630 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1630 = _1623;\n    }\n    if (_1630)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1640 = vec4(world_pos, 1.0);\n    float _1646 = dot(fa_mesh_fs_params[16], _1640);\n    if (!(_1646 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1668 = vec2(dot(fa_mesh_fs_params[14], _1640), dot(fa_mesh_fs_params[15], _1640)) / vec2(_1646);\n    int _1672 = int(fa_mesh_fs_params[18].x);\n    int _1676 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1676) + clamp(int(floor(((_1668.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1676 - 1)) * _1672)) + clamp(int(floor(((_1668.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1672 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1752 = fa_cluster_texel(param);\n    return ivec2(int(_1752.x), int(_1752.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6292 = fa_cluster_lookup(param);\n    fa_cl_slot = _6292.x;\n    fa_cl_local = _6292.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7481 = fa_linear_to_srgb(param);\n        c = _7481;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7489 = fa_srgb_to_linear(param_1);\n            c = _7489;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _545;\n    if (i.front_facing)\n    {\n        _545 = i.world_normal;\n    }\n    else\n    {\n        _545 = -i.world_normal;\n    }\n    vec3 _569 = normalize(i.world_tangent.xyz - (_545 * dot(_545, i.world_tangent.xyz)));\n    vec3 _596 = normalize(((_569 * m.x) + ((cross(_545, _569) * i.world_tangent.w) * m.y)) + (_545 * m.z));\n    vec3 _599;\n    if (i.front_facing)\n    {\n        _599 = _596;\n    }\n    else\n    {\n        _599 = -_596;\n    }\n    return _599;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7521 = fa_tex_fix(param_2, param_3);\n    vec4 _9812 = base_t;\n    _9812.x = _7521.x;\n    _9812.y = _7521.y;\n    _9812.z = _7521.z;\n    base_t = _9812;\n    vec4 _7535 = (_9812 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9567 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7569 = fa_tex_fix(param_6, param_7);\n        vec3 _7572 = (_7569 * 2.0) - vec3(1.0);\n        vec2 _7577 = _7572.xy * fa_mesh_fs_params[6].x;\n        vec3 _9820 = _7572;\n        _9820.x = _7577.x;\n        _9820.y = _7577.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9820;\n        _9567 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7607 = fa_tex_fix(param_12, param_13);\n    vec4 _9823 = mrt;\n    _9823.x = _7607.x;\n    _9823.y = _7607.y;\n    _9823.z = _7607.z;\n    mrt = _9823;\n    vec4 _7637 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7637.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7648 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7680 = fa_tex_fix(param_20, param_21);\n    float _9572 = fa_mesh_fs_params[20].x;\n    float _9573 = fa_mesh_fs_params[20].y;\n    float _9576 = fa_mesh_fs_params[20].z;\n    float _9575 = fa_mesh_fs_params[21].w;\n    float _9578 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9572 *= _7648.y;\n            _9573 *= _7648.z;\n            _9575 *= _7637.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9576 *= mrt.x;\n            _9578 *= mrt.w;\n        }\n    }\n    return Surface(_7535.xyz, _7535.w, _9567, clamp(fa_mesh_fs_params[5].x * _7607.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7607.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7648.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7680), _9572, _9573, fa_mesh_fs_params[21].xyz, _9575, _9576, fa_mesh_fs_params[20].w, _9578, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1832 = rect.zw - rect.xy;\n    vec2 _1836 = _1832 * atlas;\n    vec2 _1840 = ddx * _1836;\n    vec2 _1844 = ddy * _1836;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1832), clamp(0.5 * log2(max(max(dot(_1840, _1840), dot(_1844, _1844)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1877 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1884;\n    if (!_1877)\n    {\n        _1884 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1884 = _1877;\n    }\n    if (_1884)\n    {\n        return;\n    }\n    vec3 _1890 = dFdx(world_pos);\n    vec3 _1893 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1897 = fa_cluster_texel(param);\n    int _1901 = int(_1897.w);\n    if (_1901 < 1)\n    {\n        return;\n    }\n    int _1911 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1911;\n    vec4 _1915 = fa_light_texel(param_1);\n    vec2 _1918 = _1915.yz;\n    int _1922 = int(_1915.w);\n    int param_2 = _1911 + 1;\n    vec4 _1927 = fa_light_texel(param_2);\n    float _1928 = _1927.x;\n    int _1934 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1938 = int(_1897.z);\n    vec3 _2203;\n    for (int k = 0; k < _1901; k++)\n    {\n        int _1951 = _1938 + k;\n        int param_3 = _1922 + (_1951 >> 2);\n        int _1968 = (_1911 + 2) + (int(fa_light_texel(param_3)[_1951 & 3]) * 7);\n        int param_4 = _1968 + 6;\n        vec4 _1973 = fa_light_texel(param_4);\n        if (((int(_1973.w + 0.5) >> _1934) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1968;\n        vec4 _1988 = fa_light_texel(param_5);\n        int param_6 = _1968 + 1;\n        vec4 _1993 = fa_light_texel(param_6);\n        int param_7 = _1968 + 2;\n        vec4 _1998 = fa_light_texel(param_7);\n        vec3 _2001 = _1988.xyz;\n        float _2006 = dot(_2001, world_pos) + _1988.w;\n        vec3 _2008 = _1993.xyz;\n        float _2013 = dot(_2008, world_pos) + _1993.w;\n        vec3 _2015 = _1998.xyz;\n        float _2020 = dot(_2015, world_pos) + _1998.w;\n        bool _2025 = abs(_2006) > 0.5;\n        bool _2033;\n        if (!_2025)\n        {\n            _2033 = abs(_2013) > 0.5;\n        }\n        else\n        {\n            _2033 = _2025;\n        }\n        bool _2041;\n        if (!_2033)\n        {\n            _2041 = abs(_2020) > 0.5;\n        }\n        else\n        {\n            _2041 = _2033;\n        }\n        if (_2041)\n        {\n            continue;\n        }\n        float _2056 = clamp(dot(geo_normal, normalize(_2015)) * _1973.z, 0.0, 1.0);\n        if (_2056 <= 0.0)\n        {\n            continue;\n        }\n        float _2076 = (clamp((0.5 - abs(_2020)) * 10.0, 0.0, 1.0) * _2056) * _1973.x;\n        vec2 _2084 = vec2(_2006 + 0.5, 0.5 - _2013);\n        vec2 _2094 = vec2(dot(_2001, _1890), dot(_2008, _1890));\n        vec2 _2104 = vec2(dot(_2001, _1893), dot(_2008, _1893));\n        int param_8 = _1968 + 5;\n        vec4 _2109 = fa_light_texel(param_8);\n        int param_9 = _1968 + 3;\n        vec4 _2114 = fa_light_texel(param_9);\n        int param_10 = _1968 + 4;\n        vec4 _2119 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2109.xyz;\n        bool _2129 = _2114.z > _2114.x;\n        if (_2129)\n        {\n            vec4 param_11 = _2114;\n            vec2 param_12 = _2084;\n            vec2 param_13 = _1918;\n            vec2 param_14 = _2094;\n            vec2 param_15 = _2104;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1928 > 0.5) && (_1928 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2155 = fa_dc_to_linear(param_16);\n                vec4 _9655 = tx;\n                _9655.x = _2155.x;\n                _9655.y = _2155.y;\n                _9655.z = _2155.z;\n                tx = _9655;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2076 * tex_a) * _2109.w, 0.0, 1.0)));\n        if (_2119.z > _2119.x)\n        {\n            vec4 param_17 = _2119;\n            vec2 param_18 = _2084;\n            vec2 param_19 = _1918;\n            vec2 param_20 = _2094;\n            vec2 param_21 = _2104;\n            vec4 _2199 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1928 > 1.5)\n            {\n                vec3 param_22 = _2199.xyz;\n                vec3 _2209 = fa_dc_to_srgb(param_22);\n                _2203 = _2209;\n            }\n            else\n            {\n                _2203 = _2199.xyz;\n            }\n            vec3 _2218 = (_2203 * 2.0) - vec3(1.0);\n            vec2 _2223 = _2218.xy * _1973.y;\n            vec3 _2245 = (normalize(_2001) * _2223.x) + (normalize(_2008) * _2223.y);\n            vec3 _2248 = normalize(normal);\n            normal = normalize(mix(_2248, normalize((_2248 * max(_2218.z, 0.0500000007450580596923828125)) + (_2245 - (_2248 * dot(_2248, _2245)))), vec3(clamp(_2076 * (_2129 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4750 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4758 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4761 = int(_4750);\n    int _4764 = int(_4758);\n    float _4774 = _4758 - float(_4764);\n    int _4829 = (_4761 * 9) + _4764;\n    int _4849 = ((_4761 + 1) * 9) + _4764;\n    return mix(mix(_4825[_4829], _4825[_4829 + 1], _4774), mix(_4825[_4849], _4825[_4849 + 1], _4774), _4750 - float(_4761));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9490 = false;\n    float _9491 = 1.0;\n    float _9492 = 1.0;\n    float _9493 = 1.0;\n    float _9494 = 0.0;\n    float _9495 = 0.0;\n    float _9496 = 0.0;\n    float _9497 = 0.0;\n    float _9499 = 1.0;\n    bool _9500 = false;\n    vec3 _9501 = vec3(0.0);\n    float _9502 = 1.0;\n    float _9503 = 1.0;\n    float _9504 = 1.0;\n    float _9505 = 0.0;\n    float _9506 = 0.0;\n    vec3 _9507 = vec3(1.0, 0.0, 0.0);\n    vec3 _9508 = vec3(0.0, 0.0, 1.0);\n    float _9509 = 1.0;\n    float _9510 = 1.0;\n    float _4900 = clamp(s.specular, 0.0, 1.0);\n    float _4904 = clamp(s.ior, 1.0, 3.0);\n    bool _4909 = (_4900 != 1.0) || (_4904 != 1.5);\n    bool _4918;\n    if (!_4909)\n    {\n        _4918 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4918 = _4909;\n    }\n    if (_4918)\n    {\n        float _4926 = (_4904 - 1.0) / (_4904 + 1.0);\n        f0 = mix(min(vec3(_4926 * _4926) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4900, s.albedo, vec3(metallic));\n        _9491 = mix(_4900, 1.0, metallic);\n        _9490 = true;\n    }\n    float _4953 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4953 > 0.0)\n    {\n        float _4961 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9494 = _4953;\n        _9495 = _4961;\n        float _4968 = _4961 * _4961;\n        _9496 = _4968;\n        _9497 = _4968 * _4968;\n        float _4980 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9499 = _4980;\n        _9492 = 1.0 - (_4953 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4980, 0.0, 1.0), 5.0))));\n        _9490 = true;\n    }\n    vec3 _4999 = max(s.sheen_color, vec3(0.0));\n    float _5008 = max(_4999.x, max(_4999.y, _4999.z));\n    if (_5008 > 0.0)\n    {\n        float _5016 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9500 = true;\n        _9501 = _4999;\n        _9502 = _5016;\n        _9503 = _5016 * _5016;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5016;\n        float _5033 = fa_sheen_albedo(param, param_1);\n        _9505 = _5033;\n        _9504 = 1.0 - min(_5008 * _5033, 1.0);\n        _9490 = true;\n    }\n    _9493 = _9492 * _9504;\n    float _5052 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5052 != 0.0)\n    {\n        vec3 _5067 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5067;\n        if (dot(_5067, _5067) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5079 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5079.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5079.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5079.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5083 = t;\n        vec3 _5084 = normalize(_5083);\n        t = _5084;\n        vec3 _5109 = normalize((_5084 * cos(s.anisotropy_rotation)) + ((cross(n, _5084) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9507 = _5109;\n        _9508 = cross(n, _5109);\n        float _5119 = roughness * roughness;\n        float _5125 = mix(_5119, 1.0, _5052 * _5052);\n        bool _5127 = _5052 > 0.0;\n        _9509 = _5127 ? _5125 : _5119;\n        _9510 = _5127 ? _5119 : _5125;\n        _9506 = _5052;\n        _9490 = true;\n    }\n    return FaLayers(_9490, _9491, _9492, _9493, _9494, _9495, _9496, _9497, i.world_normal, _9499, _9500, _9501, _9502, _9503, _9504, _9505, _9506, _9507, _9508, _9509, _9510);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3920 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3920;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4531 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4536 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4531 > 0.0005000000237487256526947021484375)\n    {\n        if (_4536)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4531;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4531;\n        }\n    }\n    bool _4587 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4587)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4618 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4618)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4536 || _4587) || _4618)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3940 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3943 = _3940.x;\n    float _3945 = _3940.z;\n    vec2 e = vec2(_3943, _3945);\n    if (_3940.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3945)) * ((_3943 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3943)) * ((_3945 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7790 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7795 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7800 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7805 = fa_light_texel(param_3);\n    bool _7808 = _7805.z < 0.5;\n    bool _7816;\n    if (!_7808)\n    {\n        _7816 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7816 = _7808;\n    }\n    if (_7816)\n    {\n        return vec3(0.0);\n    }\n    float _7823 = max(_7790.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7826 = _7795.xyz;\n    vec3 _7830 = _7790.xyz;\n    vec3 _7834 = (fa_world_pos - _7830) / vec3(_7823);\n    vec3 _7843 = min(_7834 + vec3(0.5), (_7826 - vec3(0.5)) - _7834);\n    float _7852 = min(_7843.x, min(_7843.y, _7843.z));\n    if (!(_7852 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7867 = _7826 - vec3(1.0);\n    vec3 _7868 = clamp(_7834, vec3(0.0), _7867);\n    vec3 _7876 = min(floor(_7868), max(_7826 - vec3(2.0), vec3(0.0)));\n    vec3 _7880 = _7868 - _7876;\n    vec3 _7891 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7823));\n    int _7896 = int(_7800.y + 0.5);\n    float _7901 = 0.3257350027561187744140625 * n.y;\n    float _7905 = 0.3257350027561187744140625 * n.z;\n    float _7909 = 0.3257350027561187744140625 * n.x;\n    float _7916 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7923 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7932 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7939 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7952 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7959 = 8 + int(_7805.w);\n    float _7986;\n    float _7999;\n    float _8013;\n    for (int k = 0; k < _7959; k++)\n    {\n        float _7972 = float(k & 1);\n        float _7976 = float((k >> 1) & 1);\n        float _7980 = float((k >> 2) & 1);\n        if (_7972 > 0.5)\n        {\n            _7986 = _7880.x;\n        }\n        else\n        {\n            _7986 = 1.0 - _7880.x;\n        }\n        if (_7976 > 0.5)\n        {\n            _7999 = _7880.y;\n        }\n        else\n        {\n            _7999 = 1.0 - _7880.y;\n        }\n        if (_7980 > 0.5)\n        {\n            _8013 = _7880.z;\n        }\n        else\n        {\n            _8013 = 1.0 - _7880.z;\n        }\n        float _8023 = (_7986 * _7999) * _8013;\n        if (!(_8023 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8036 = min(_7876 + vec3(_7972, _7976, _7980), _7867);\n        int _8056 = int(((_7800.x + _8036.x) + (_7795.x * (_8036.y + (_7795.y * _8036.z)))) + 0.5);\n        vec2 _8071 = vec2(float(_8056 % _7896) * 10.0, 1024.0 + (float(_8056 / _7896) * 11.0));\n        vec2 param_4 = _8071 + vec2(9.5, 10.5);\n        vec4 _8079 = fa_gi_fetch(param_4);\n        bool _8082 = _8079.y < 0.5;\n        bool _8091;\n        if (!_8082)\n        {\n            _8091 = _8079.x > _7805.y;\n        }\n        else\n        {\n            _8091 = _8082;\n        }\n        if (_8091)\n        {\n            continue;\n        }\n        vec3 _8103 = _7891 - (_7830 + (_8036 * _7823));\n        float _8106 = length(_8103);\n        vec3 _8112 = _8103 / vec3(max(_8106, 9.9999997473787516355514526367188e-05));\n        float _8122 = max(9.9999997473787516355514526367188e-05, (dot(-_8112, n) + 1.0) * 0.5);\n        float w = _8023 * (_8122 * _8122);\n        vec3 param_5 = _8112;\n        vec2 param_6 = (_8071 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8141 = fa_gi_fetch(param_6);\n        float _8148 = _8106 / max(_7800.z, 9.9999997473787516355514526367188e-05);\n        float _8151 = _8141.x;\n        if (_8148 > _8151)\n        {\n            float _8164 = max(_8141.y - (_8151 * _8151), 0.0);\n            float _8169 = _8148 - _8151;\n            float _8178 = _8164 / max(_8164 + (_8169 * _8169), 9.9999999600419720025001879548654e-13);\n            w *= ((_8178 * _8178) * _8178);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8071 + vec2(0.5, 10.5);\n        vec2 param_8 = _8071 + vec2(1.5, 10.5);\n        vec2 param_9 = _8071 + vec2(2.5, 10.5);\n        vec2 param_10 = _8071 + vec2(3.5, 10.5);\n        vec2 param_11 = _8071 + vec2(4.5, 10.5);\n        vec2 param_12 = _8071 + vec2(5.5, 10.5);\n        vec2 param_13 = _8071 + vec2(6.5, 10.5);\n        vec2 param_14 = _8071 + vec2(7.5, 10.5);\n        vec2 param_15 = _8071 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7901)) + (fa_gi_fetch(param_9).xyz * _7905)) + (fa_gi_fetch(param_10).xyz * _7909)) + (fa_gi_fetch(param_11).xyz * _7916)) + (fa_gi_fetch(param_12).xyz * _7923)) + (fa_gi_fetch(param_13).xyz * _7932)) + (fa_gi_fetch(param_14).xyz * _7939)) + (fa_gi_fetch(param_15).xyz * _7952)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7852 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8303;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8303 = _7805.x;\n    }\n    else\n    {\n        _8303 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7800.w * _8303);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8327 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8332 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8337 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8337) && (k < 8); k++)\n    {\n        int param = _8332 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8327;\n        vec3 _8362 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8367 = param_3 * left;\n        acc += (_8362 * _8367);\n        left -= _8367;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8396 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8396;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6262;\n    if (fa_lm.z > 0.5)\n    {\n        _6262 = 0.0;\n    }\n    else\n    {\n        _6262 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6273 = _6262 < 1.0;\n    bool _6279;\n    if (_6273)\n    {\n        int param = li;\n        _6279 = fa_light_baked(param);\n    }\n    else\n    {\n        _6279 = _6273;\n    }\n    return _6279 ? _6262 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _850 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _863 = (c - (ru * hx)) - p;\n        vec3 _869 = ru * (2.0 * hx);\n        float _875 = max(dot(_869, _869), 9.9999999392252902907785028219223e-09);\n        float _879 = dot(_863, _869);\n        float t = clamp((-_879) / _875, 0.0, 1.0);\n        if (_850)\n        {\n            float _894 = dot(r, _869);\n            float _900 = _875 - (_894 * _894);\n            if (abs(_900) > (9.9999997473787516355514526367188e-06 * _875))\n            {\n                t = clamp(((dot(r, _863) * _894) - _879) / _900, 0.0, 1.0);\n            }\n        }\n        return (p + _863) + (_869 * t);\n    }\n    vec3 q = p;\n    float _932 = dot(r, axis);\n    bool _940;\n    if (_850)\n    {\n        _940 = abs(_932) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _940 = _850;\n    }\n    if (_940)\n    {\n        float _950 = dot(c - p, axis) / _932;\n        if (_950 > 0.0)\n        {\n            q = p + (r * _950);\n        }\n    }\n    vec3 _963 = q - c;\n    vec2 xy = vec2(dot(_963, ru), dot(_963, uu));\n    if (shape > 0.5)\n    {\n        float _978 = length(xy);\n        if (_978 > hx)\n        {\n            xy *= (hx / _978);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _611 = abs(d);\n    float _613 = _611.x;\n    float _615 = _611.y;\n    bool _616 = _613 >= _615;\n    bool _624;\n    if (_616)\n    {\n        _624 = _613 >= _611.z;\n    }\n    else\n    {\n        _624 = _616;\n    }\n    int _625;\n    if (_624)\n    {\n        _625 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _640;\n        if (_615 >= _611.z)\n        {\n            _640 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _640 = (d.z > 0.0) ? 4 : 5;\n        }\n        _625 = _640;\n    }\n    return _625;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _770 = dot(d, right);\n    float _774 = dot(d, up);\n    float _785;\n    if (((_770 * _770) + (_774 * _774)) > 1.0000000133514319600180897396058e-10)\n    {\n        _785 = atan(_774, _770) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _785 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_785 - floor(_785)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1016 = fa_light_base(param);\n    bool _1020 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1016;\n    vec4 _1024 = fa_light_texel(param_1);\n    int param_2 = _1016 + 1;\n    vec4 _1029 = fa_light_texel(param_2);\n    float _1032 = _1029.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1044 = _1020 && (_1032 > 2.5);\n    fa_light_is_area = _1044;\n    bool _1046 = _1032 < 0.5;\n    vec3 l;\n    if (_1046)\n    {\n        l = normalize(_1024.xyz);\n        if (_1020)\n        {\n            int param_3 = _1016 + 6;\n            vec4 _1060 = fa_light_texel(param_3);\n            if (_1060.z > 0.5)\n            {\n                int param_4 = _1016 + 4;\n                vec4 _1070 = fa_light_texel(param_4);\n                int param_5 = _1016 + 5;\n                vec4 _1075 = fa_light_texel(param_5);\n                vec2 param_6 = _1060.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1070.xyz) * _1070.w, (-dot(world_pos, _1075.xyz)) * _1075.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1105 = _1024.xyz;\n        vec3 _1107 = _1105 - world_pos;\n        vec3 to_light = _1107;\n        float _1110 = length(_1107);\n        float reach = _1110;\n        bool front = true;\n        if (_1044)\n        {\n            int param_8 = _1016 + 7;\n            reach = max(_1110 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1016 + 4;\n            vec4 _1134 = fa_light_texel(param_9);\n            int param_10 = _1016 + 5;\n            vec4 _1139 = fa_light_texel(param_10);\n            int param_11 = _1016 + 6;\n            vec4 _1144 = fa_light_texel(param_11);\n            float _1145 = _1144.w;\n            int param_12 = _1016 + 2;\n            vec3 _1152 = normalize(fa_light_texel(param_12).xyz);\n            bool _1154 = _1145 > 1.5;\n            bool _1162;\n            if (!_1154)\n            {\n                _1162 = dot(_1152, to_light) < 0.0;\n            }\n            else\n            {\n                _1162 = _1154;\n            }\n            front = _1162;\n            vec3 r = vec3(0.0);\n            vec3 _1171 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1175 = dot(n, n) > 0.5;\n            bool _1183;\n            if (_1175)\n            {\n                _1183 = dot(_1171, _1171) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1183 = _1175;\n            }\n            if (_1183)\n            {\n                r = reflect(-normalize(_1171), normalize(n));\n            }\n            vec3 param_13 = _1105;\n            vec3 param_14 = _1152;\n            vec3 param_15 = _1134.xyz;\n            vec3 param_16 = _1139.xyz;\n            float param_17 = _1134.w;\n            float param_18 = _1139.w;\n            float param_19 = _1145;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1219 = length(to_light);\n        dist = _1219;\n        l = to_light / vec3(max(_1219, 9.9999997473787516355514526367188e-05));\n        float _1233 = reach / max(_1024.w, 0.001000000047497451305389404296875);\n        float _1239 = clamp(1.0 - (_1233 * _1233), 0.0, 1.0);\n        float _1241;\n        if (front)\n        {\n            _1241 = _1239 * _1239;\n        }\n        else\n        {\n            _1241 = 0.0;\n        }\n        atten = _1241;\n        bool _1252 = _1032 < 2.5;\n        if ((_1032 > 1.5) && _1252)\n        {\n            int param_22 = _1016 + 2;\n            vec4 _1260 = fa_light_texel(param_22);\n            float _1270 = _1260.w;\n            int param_23 = _1016 + 3;\n            vec4 _1275 = fa_light_texel(param_23);\n            float _1276 = _1275.x;\n            float cos_inner = _1276;\n            if (_1276 > 1.5)\n            {\n                cos_inner = mix(_1270, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1270, cos_inner, dot(-l, normalize(_1260.xyz)));\n        }\n        if (_1020 && (_1032 < 1.5))\n        {\n            int param_24 = _1016 + 6;\n            vec4 _1300 = fa_light_texel(param_24);\n            if (_1300.z > 0.5)\n            {\n                vec3 _1308 = -to_light;\n                int param_25 = _1016 + 4;\n                int param_26 = _1016 + 5;\n                vec3 _1322 = fa_light_texel(param_25).xyz;\n                vec3 _1326 = fa_light_texel(param_26).xyz;\n                vec3 _1335 = vec3(dot(_1308, _1322), dot(_1308, _1326), dot(_1308, cross(_1322, _1326)));\n                vec3 param_27 = _1335;\n                int _1339 = fa_cube_face(param_27);\n                int param_28 = _1339;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1366 = vec2(dot(_1335, cross(param_29, param_30)), dot(_1335, param_30)) / vec2(max(dot(_1335, param_29), 9.9999997473787516355514526367188e-05));\n                int _1370 = _1339 / 3;\n                vec2 param_31 = _1300.xy + (vec2(float(_1339 - (_1370 * 3)), float(_1370)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1366.x), 0.5 - (0.5 * _1366.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1016 + 7;\n            vec4 _1400 = fa_light_texel(param_33);\n            if (_1400.z > 0.5)\n            {\n                int param_34 = _1016 + 2;\n                int param_35 = _1016 + 4;\n                int param_36 = _1016 + 5;\n                vec2 param_37 = _1400.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1020 && _1252)\n            {\n                int param_42 = _1016 + 6;\n                vec4 _1447 = fa_light_texel(param_42);\n                int param_43 = _1016 + 7;\n                vec4 _1452 = fa_light_texel(param_43);\n                bool _1455 = _1447.z > 0.5;\n                bool _1462;\n                if (!_1455)\n                {\n                    _1462 = _1452.z > 0.5;\n                }\n                else\n                {\n                    _1462 = _1455;\n                }\n                if (_1462)\n                {\n                    int param_44 = _1016 + 2;\n                    vec4 _1469 = fa_light_texel(param_44);\n                    vec3 _1473 = normalize(_1469.xyz);\n                    int param_45 = _1016 + 4;\n                    vec4 _1478 = fa_light_texel(param_45);\n                    int param_46 = _1016 + 5;\n                    vec4 _1483 = fa_light_texel(param_46);\n                    if (_1455)\n                    {\n                        vec3 _1491 = -to_light;\n                        float _1498 = _1469.w;\n                        float _1514 = 0.5 / max(dot(_1491, _1473) * (sqrt(max(1.0 - (_1498 * _1498), 0.0)) / max(_1498, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1447.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1491, _1478.xyz) * _1514), 0.5 - (dot(_1491, _1483.xyz) * _1514));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1452.z > 0.5)\n                    {\n                        vec2 param_49 = _1452.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1473;\n                        vec3 param_52 = _1478.xyz;\n                        vec3 param_53 = _1483.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9478 = _1029.xyz * atten;\n    if (_1020)\n    {\n        _9478 *= fa_light_tint;\n    }\n    int _1583;\n    if (_1046)\n    {\n        _1583 = 0;\n    }\n    else\n    {\n        _1583 = ((_1032 > 1.5) && (_1032 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9478, atten, 1.0, dist, _1583);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2315;\n    if (i == 0)\n    {\n        _2315 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2331;\n        if (i == 1)\n        {\n            _2331 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2339;\n            if (i == 2)\n            {\n                _2339 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2339 = fa_shadows[24].w;\n            }\n            _2331 = _2339;\n        }\n        _2315 = _2331;\n    }\n    return _2315;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2372 = fa_shadow_depth(param, param_1);\n    float _2376;\n    if (conv.x < 0.5)\n    {\n        _2376 = _2372;\n    }\n    else\n    {\n        _2376 = (conv.y * conv.z) / (conv.z - (_2372 * (conv.z - conv.y)));\n    }\n    return _2376;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2422 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2428 = vec2(cos(_2422), sin(_2422));\n    vec2 dir = _2428;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2437;\n        if (k < 0.0)\n        {\n            _2437 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2437 = k;\n        }\n        float _2456 = clamp((_2437 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2475 = sqrt((float(i) + 0.5) * 0.0625) * _2456;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2475));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2489 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2489 < (zr - (_2475 * plane)))\n            {\n                sum += _2489;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2517 = sum / cnt;\n        float _2527;\n        if (k < 0.0)\n        {\n            _2527 = (-k) / max(_2517, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2527 = k;\n        }\n        radius = clamp(((max(zr - _2517, 0.0) * unit) * _2527) / texel_m, 1.5, 16.0);\n        dir = _2428;\n    }\n    float lit = 0.0;\n    int _2553 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2553; i_1++)\n    {\n        float _2572 = sqrt((float(i_1) + 0.5) / float(_2553)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2572));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2572 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2553);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2618 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2623 = clamp(dot(n, l), 0.0, 1.0);\n    float _2629 = sqrt(1.0 - (_2623 * _2623));\n    float _2637 = min(_2629 / max(_2623, 0.20000000298023223876953125), 4.0);\n    float _2642;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2642 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2642 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2667 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2642 * _2629)), 1.0);\n    float _2674 = _2667.x;\n    bool _2677 = _2674 < fa_shadows[ci * 1 + 16].x;\n    bool _2686;\n    if (!_2677)\n    {\n        _2686 = _2674 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2686 = _2677;\n    }\n    bool _2695;\n    if (!_2686)\n    {\n        _2695 = _2667.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2695 = _2686;\n    }\n    bool _2704;\n    if (!_2695)\n    {\n        _2704 = _2667.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2704 = _2695;\n    }\n    bool _2711;\n    if (!_2704)\n    {\n        _2711 = _2667.z > 1.0;\n    }\n    else\n    {\n        _2711 = _2704;\n    }\n    if (_2711)\n    {\n        return -1.0;\n    }\n    float _2719;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2719 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2719 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2667.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2667.z - ((_2719 * (1.0 + (0.5 * _2637))) / _2618);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2618;\n    float param_5 = _2618 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2637, 3.0)) * 0.5) / _2618;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3097 = int(fa_shadows[25].x + 0.5);\n    if (_3097 < 1)\n    {\n        return 1.0;\n    }\n    float _3112 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3097 - 1;\n    if (_3112 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3124 = _3097 > 1;\n    bool _3131;\n    if (_3124)\n    {\n        _3131 = _3112 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3131 = _3124;\n    }\n    if (_3131)\n    {\n        ci = 1;\n    }\n    bool _3135 = _3097 > 2;\n    bool _3142;\n    if (_3135)\n    {\n        _3142 = _3112 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3142 = _3135;\n    }\n    if (_3142)\n    {\n        ci = 2;\n    }\n    bool _3146 = _3097 > 3;\n    bool _3153;\n    if (_3146)\n    {\n        _3153 = _3112 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3153 = _3146;\n    }\n    if (_3153)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3164 = min(_3097, 4);\n    float _3205;\n    for (int c = ci; c < _3164; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3184 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3184;\n            break;\n        }\n        if (_3184 < 0.0)\n        {\n            continue;\n        }\n        s = _3184;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3205 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3205 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3224 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3205, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3112 - (fa_shadow_split_at(param_7) - _3224)) / _3224, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3256;\n        if ((ci + 1) < _3097)\n        {\n            _3256 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3256 = 1.0;\n        }\n        s = mix(s, _3256, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3361 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3367;\n    if (_3361)\n    {\n        _3367 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3367 = _3361;\n    }\n    if (_3367)\n    {\n        float _3381 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3384 = fwidth(_3381);\n        vec4 _3394 = vec4(fa_world_pos, 1.0);\n        float _3400 = dot(fa_mesh_fs_params[28], _3394);\n        if (_3400 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3419 = vec2(dot(fa_mesh_fs_params[26], _3394), dot(fa_mesh_fs_params[27], _3394)) / vec2(_3400);\n            float _3424 = (_3419.x * 0.5) + 0.5;\n            float _3428;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3428 = (_3419.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3428 = 0.5 - (_3419.y * 0.5);\n            }\n            bool _3444 = _3424 >= 0.0;\n            bool _3450;\n            if (_3444)\n            {\n                _3450 = _3424 < 1.0;\n            }\n            else\n            {\n                _3450 = _3444;\n            }\n            bool _3456;\n            if (_3450)\n            {\n                _3456 = _3428 >= 0.0;\n            }\n            else\n            {\n                _3456 = _3450;\n            }\n            bool _3462;\n            if (_3456)\n            {\n                _3462 = _3428 < 1.0;\n            }\n            else\n            {\n                _3462 = _3456;\n            }\n            if (_3462)\n            {\n                vec4 _3488 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3424, _3428) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3491 = _3488.w > 0.5;\n                bool _3507;\n                if (_3491)\n                {\n                    _3507 = abs(_3381 - _3488.x) <= (((0.00200000009499490261077880859375 * _3381) + 0.00999999977648258209228515625) + min(1.5 * _3384, 0.100000001490116119384765625 * _3381));\n                }\n                else\n                {\n                    _3507 = _3491;\n                }\n                if (_3507)\n                {\n                    float _3513;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3513 = min(_3488.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3513 = _3488.y;\n                    }\n                    return _3513;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2777 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2784;\n    if (!_2777)\n    {\n        _2784 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2784 = _2777;\n    }\n    if (_2784)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2797 = fa_light_texel(param);\n    float _2798 = _2797.x;\n    if (_2798 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2807 = int(_2798 + 0.5);\n    int param_1 = _2807;\n    vec4 _2811 = fa_light_texel(param_1);\n    int param_2 = _2807 + 1;\n    vec4 _2816 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2819 = _2811.y;\n    if (_2819 > 0.0)\n    {\n        float _2836 = 1.0 - smoothstep(0.75 * _2819, _2819, length(world - fa_shadows[27].xyz));\n        fade = _2836;\n        if (_2836 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2811.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2860 = (_2807 + 2) + (face * 6);\n    int param_4 = _2860;\n    int param_5 = _2860 + 1;\n    int param_6 = _2860 + 3;\n    vec4 _2874 = fa_light_texel(param_6);\n    int param_7 = _2860 + 4;\n    vec4 _2879 = fa_light_texel(param_7);\n    int param_8 = _2860 + 5;\n    vec4 _2884 = fa_light_texel(param_8);\n    float _2896 = _2884.x * max(dot(_2874, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2901 = clamp(dot(n, l), 0.0, 1.0);\n    float _2924 = clamp(dot(n, _2874.xyz), -1.0, 1.0);\n    float _2943 = min(sqrt(1.0 - (_2924 * _2924)) / max(abs(dot(n, world - lpos)) / max(dot(_2874, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2946 = _2816.y;\n    float _2948;\n    if (_2946 > 0.0)\n    {\n        _2948 = _2946;\n    }\n    else\n    {\n        _2948 = 1.5 * _2896;\n    }\n    vec4 _2968 = vec4(world + (n * (_2948 * sqrt(1.0 - (_2901 * _2901)))), 1.0);\n    float _2972 = dot(_2874, _2968);\n    float _2975 = _2884.y;\n    if (_2972 < _2975)\n    {\n        return 1.0;\n    }\n    vec2 _2990 = vec2(dot(fa_light_texel(param_4), _2968), dot(fa_light_texel(param_5), _2968)) / vec2(_2972);\n    float _2992 = _2990.x;\n    bool _2995 = _2992 < _2879.x;\n    bool _3004;\n    if (!_2995)\n    {\n        _3004 = _2992 > _2879.z;\n    }\n    else\n    {\n        _3004 = _2995;\n    }\n    bool _3013;\n    if (!_3004)\n    {\n        _3013 = _2990.y < _2879.y;\n    }\n    else\n    {\n        _3013 = _3004;\n    }\n    bool _3022;\n    if (!_3013)\n    {\n        _3022 = _2990.y > _2879.w;\n    }\n    else\n    {\n        _3022 = _3013;\n    }\n    if (_3022)\n    {\n        return 1.0;\n    }\n    float _3028 = _2816.x;\n    float _3030;\n    if (_3028 > 0.0)\n    {\n        _3030 = _3028;\n    }\n    else\n    {\n        _3030 = 1.5 * _2896;\n    }\n    vec2 param_9 = _2990;\n    vec4 param_10 = _2879;\n    float param_11 = _2972 - (_3030 * (1.0 + (0.5 * _2943)));\n    float param_12 = _2896;\n    float param_13 = 1.0;\n    float param_14 = _2884.z * 0.25;\n    float param_15 = (_2896 * min(_2943, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2975, _2884.z);\n    int param_17 = int(_2811.z + 0.5);\n    float param_18 = _2811.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3542 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3548;\n    if (_3542)\n    {\n        _3548 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3548 = _3542;\n    }\n    bool _3554;\n    if (_3548)\n    {\n        _3554 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3554 = _3548;\n    }\n    if (_3554)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3566 = fa_light_texel(param);\n        float _3567 = _3566.z;\n        if (_3567 > 0.5)\n        {\n            float _3580 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3583 = fwidth(_3580);\n            float _3587 = min(1.5 * _3583, 0.100000001490116119384765625 * _3580);\n            vec4 _3593 = vec4(world, 1.0);\n            float _3598 = dot(fa_mesh_fs_params[28], _3593);\n            if (_3598 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3615 = vec2(dot(fa_mesh_fs_params[26], _3593), dot(fa_mesh_fs_params[27], _3593)) / vec2(_3598);\n                float _3620 = (_3615.x * 0.5) + 0.5;\n                float _3624;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3624 = (_3615.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3624 = 0.5 - (_3615.y * 0.5);\n                }\n                bool _3640 = _3620 >= 0.0;\n                bool _3646;\n                if (_3640)\n                {\n                    _3646 = _3620 < 1.0;\n                }\n                else\n                {\n                    _3646 = _3640;\n                }\n                bool _3652;\n                if (_3646)\n                {\n                    _3652 = _3624 >= 0.0;\n                }\n                else\n                {\n                    _3652 = _3646;\n                }\n                bool _3658;\n                if (_3652)\n                {\n                    _3658 = _3624 < 1.0;\n                }\n                else\n                {\n                    _3658 = _3652;\n                }\n                if (_3658)\n                {\n                    ivec2 _3675 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3676 = clamp(ivec2(vec2(_3620, _3624) * fa_mesh_fs_params[24].zw), ivec2(0), _3675);\n                    ivec2 _3688;\n                    ivec2 _3694;\n                    ivec2 _3701;\n                    float _3752;\n                    float _3773;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3688 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3694 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3701 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3712 = bvec2(k == 3);\n                                    _3701 = ivec2(_3712.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3712.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3694 = _3701;\n                            }\n                            _3688 = _3694;\n                        }\n                        vec4 _3729 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3676 + _3688, ivec2(0), _3675), 0);\n                        bool _3732 = _3729.w > 0.5;\n                        bool _3746;\n                        if (_3732)\n                        {\n                            _3746 = abs(_3580 - _3729.x) <= (((0.00200000009499490261077880859375 * _3580) + 0.00999999977648258209228515625) + _3587);\n                        }\n                        else\n                        {\n                            _3746 = _3732;\n                        }\n                        if (_3746)\n                        {\n                            if (_3567 < 1.5)\n                            {\n                                _3752 = 1.0;\n                            }\n                            else\n                            {\n                                _3752 = (_3567 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3769 = mod(floor(_3729.z / _3752), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3773 = min(_3769, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3773 = _3769;\n                            }\n                            return _3773;\n                        }\n                    }\n                }\n            }\n            float _3798;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3798 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3798 = 1.0;\n            }\n            return _3798;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5643 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5650;\n    if (!_5643)\n    {\n        _5650 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5650 = _5643;\n    }\n    if (_5650)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5663 = fa_light_texel(param);\n    float _5664 = _5663.y;\n    float len = _5664;\n    if (_5664 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5676 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5685 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5676);\n    if (_5685 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5691 = len;\n    float _5694 = min(_5691, 0.89999997615814208984375 * dist);\n    len = _5694;\n    float _5699 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5676);\n    float _5704 = _5699 + (0.5 * _5694);\n    vec3 _5710 = world + (gn * _5699);\n    float _5712 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5773;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5727 = (float(k) + _5712) * 0.083333335816860198974609375;\n        vec3 _5735 = _5710 + (l * (_5727 * len));\n        vec4 _5741 = vec4(_5735, 1.0);\n        float _5746 = dot(fa_mesh_fs_params[28], _5741);\n        if (_5746 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5764 = vec2(dot(fa_mesh_fs_params[26], _5741), dot(fa_mesh_fs_params[27], _5741)) / vec2(_5746);\n        float _5768 = _5764.x * 0.5;\n        float _5769 = _5768 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5773 = (_5764.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5773 = 0.5 - (_5764.y * 0.5);\n        }\n        bool _5789 = _5769 < 0.0;\n        bool _5796;\n        if (!_5789)\n        {\n            _5796 = _5769 >= 1.0;\n        }\n        else\n        {\n            _5796 = _5789;\n        }\n        bool _5803;\n        if (!_5796)\n        {\n            _5803 = _5773 < 0.0;\n        }\n        else\n        {\n            _5803 = _5796;\n        }\n        bool _5810;\n        if (!_5803)\n        {\n            _5810 = _5773 >= 1.0;\n        }\n        else\n        {\n            _5810 = _5803;\n        }\n        if (_5810)\n        {\n            break;\n        }\n        vec4 _5834 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5769, _5773) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5834.w < 0.5)\n        {\n            continue;\n        }\n        float _5852 = (dot(fa_mesh_fs_params[29].xyz, _5735) + fa_mesh_fs_params[29].w) - _5834.x;\n        if ((_5852 > _5699) && (_5852 < _5704))\n        {\n            occ = max(occ, (1.0 - (_5727 * _5727)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5769, 0.5 - _5768), min(_5773, 1.0 - _5773))));\n        }\n    }\n    return 1.0 - (occ * _5685);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6318 = fa_baked_keep(param);\n    if (_6318 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6344 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9547 = _6344.color;\n    float _9548 = _6344.attenuation;\n    float _9549 = _6344.shadow;\n    bool _6347 = _6344.type == 0;\n    if (_6347 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6344.direction;\n        float _6358 = fa_shadow_factor(param_5, param_6);\n        _9549 = _6358;\n        _9547 *= _6358;\n    }\n    else\n    {\n        bool _6369 = _6344.type != 0;\n        bool _6375;\n        if (_6369)\n        {\n            _6375 = _9548 > 0.0;\n        }\n        else\n        {\n            _6375 = _6369;\n        }\n        if (_6375)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6344.direction;\n            float _6394 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9549 = _6394;\n            _9547 *= _6394;\n        }\n    }\n    bool _6404 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6410;\n    if (_6404)\n    {\n        _6410 = _9548 > 0.0;\n    }\n    else\n    {\n        _6410 = _6404;\n    }\n    if (_6410)\n    {\n        float _6417;\n        if (_6347)\n        {\n            _6417 = 1000000000.0;\n        }\n        else\n        {\n            _6417 = _6344._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6344.direction;\n        float param_18 = _6417;\n        float _6435 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9549 *= _6435;\n        _9547 *= _6435;\n    }\n    float _6448 = _9548;\n    float _6449 = _6448 * _6318;\n    _9548 = _6449;\n    vec3 _6453 = _9547;\n    vec3 _6454 = _6453 * _6318;\n    _9547 = _6454;\n    return LightSample(_6344.direction, _6454, _6449, _9549, _6344._distance, _6344.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6488 = v - (n * dot(v, n));\n    vec3 t = _6488;\n    float _6492 = dot(_6488, _6488);\n    float l2 = _6492;\n    if (_6492 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6502;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6502 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6502 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6502;\n        l2 = dot(_6502, _6502);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6889;\n    if ((j == 0) || (j == 7))\n    {\n        _6889 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6899;\n        if ((j == 3) || (j == 4))\n        {\n            _6899 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6899 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6889 = _6899;\n    }\n    float _6920;\n    if ((j == 1) || (j == 2))\n    {\n        _6920 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6929;\n        if ((j == 5) || (j == 6))\n        {\n            _6929 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6929 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6920 = _6929;\n    }\n    return (pc + (ex * _6889)) + (ey * _6920);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6537 = dot(a, a);\n    float _6541 = dot(b, b);\n    if ((_6537 < 1.0000000195414813782625560981111e-24) || (_6541 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6555 = a * inversesqrt(_6537);\n    vec3 _6560 = b * inversesqrt(_6541);\n    float _6564 = dot(_6555, _6560);\n    float _6567 = abs(_6564);\n    float g = (((((((((((0.0416471660137176513671875 * _6567) - 0.1924748718738555908203125) * _6567) + 0.4179156124591827392578125) * _6567) - 0.616057217121124267578125) * _6567) + 0.777722418308258056640625) * _6567) - 0.999542415142059326171875) * _6567) + 1.570791721343994140625;\n    if (_6564 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6564 * _6564), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6555, _6560) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6624 = a.z > 0.0;\n    bool _6628 = b.z > 0.0;\n    if (_6624 && _6628)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6624 != _6628)\n        {\n            vec3 _6663 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6663.z = 0.0;\n            if (_6624)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6663;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6663;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6663;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6663;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6712 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6738 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6764 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6790 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6712;\n    vec3 param_1 = _6738;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6738;\n    vec3 param_7 = _6764;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6764;\n    vec3 param_13 = _6790;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6790;\n    vec3 param_19 = _6712;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6958 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6976;\n    for (int k = 0; k < (2 * _6958); k++)\n    {\n        bool _6973 = k >= _6958;\n        if (_6973)\n        {\n            _6976 = k - _6958;\n        }\n        else\n        {\n            _6976 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6958 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7022 = 2 * _6976;\n            int param_4 = _7022 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7022 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7022 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7059 = bvec4(_6973);\n        vec4 param_16 = vec4(_7059.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7059.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7059.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7059.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7070 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6973)\n        {\n            vec2 _9795 = sum;\n            _9795.y = _9795.y + _7070;\n            sum = _9795;\n        }\n        else\n        {\n            vec2 _9798 = sum;\n            _9798.x = _9798.x + _7070;\n            sum = _9798;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7094 = fa_light_base(param);\n    int param_1 = _7094;\n    int param_2 = _7094 + 1;\n    int param_3 = _7094 + 2;\n    int param_4 = _7094 + 4;\n    vec4 _7116 = fa_light_texel(param_4);\n    int param_5 = _7094 + 5;\n    vec4 _7121 = fa_light_texel(param_5);\n    int param_6 = _7094 + 6;\n    vec4 _7126 = fa_light_texel(param_6);\n    float _7127 = _7126.w;\n    vec3 _7132 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7134 = _7127 < 1.5;\n    bool _7141;\n    if (_7134)\n    {\n        _7141 = dot(normalize(fa_light_texel(param_3).xyz), _7132) >= 0.0;\n    }\n    else\n    {\n        _7141 = _7134;\n    }\n    if (_7141)\n    {\n        return vec3(0.0);\n    }\n    bool _7150 = (_7127 > 0.5) && _7134;\n    float _7154 = _7150 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7157 = _7116.xyz;\n    float _7159 = _7116.w;\n    vec3 _7165 = _7121.xyz;\n    float _7167 = _7121.w;\n    vec3 up = _7165 * (_7167 * _7154);\n    float _7173;\n    if (_7150)\n    {\n        _7173 = (3.1415927410125732421875 * _7159) * _7159;\n    }\n    else\n    {\n        _7173 = (4.0 * _7159) * _7167;\n    }\n    if (_7127 > 1.5)\n    {\n        vec3 _7199 = cross(_7157, -_7132);\n        vec3 perp = _7199;\n        float _7203 = dot(_7199, _7199);\n        vec3 _7206;\n        if (_7203 > 1.0000000133514319600180897396058e-10)\n        {\n            _7206 = perp * inversesqrt(_7203);\n        }\n        else\n        {\n            _7206 = _7165;\n        }\n        perp = _7206;\n        up = _7206 * _7167;\n    }\n    float _7227 = max(_7173, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7237 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7237;\n    vec3 param_10 = n;\n    vec3 param_11 = _7132;\n    vec3 param_12 = _7237;\n    vec3 param_13 = n;\n    vec3 param_14 = _7157 * (_7159 * _7154);\n    vec3 param_15 = _7237;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7268 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7268;\n    vec2 param_21 = _7268 + vec2(64.0, 0.0);\n    vec4 _7278 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7127;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7290 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7290.x) + (((f0 * _7278.x) + ((vec3(f90) - f0) * _7278.y)) * _7290.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7132, _7132)) + _7227) / _7227) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5380 = 1.0 / alpha;\n    return ((2.0 + _5380) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5380)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5415 = max(dot(L.nc, l), 0.0);\n    float _5421 = max(dot(L.nc, h), 0.0);\n    float _5430 = ((_5421 * _5421) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5430) * _5430)) * (0.5 / max(mix((2.0 * _5415) * L.coat_ndv, _5415 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5415)) * _5415;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7327;\n    if (L.sheen_on)\n    {\n        _7327 = L.sheen_scale;\n    }\n    else\n    {\n        _7327 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7327);\n    vec3 _7340 = normalize(l + v);\n    int param = li;\n    vec3 _7351 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7360 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7340), 0.0);\n        float param_3 = _7360;\n        float param_4 = ndv;\n        result += ((L.sheen * _7351) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7360)) * _7360) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7340;\n        float param_8 = max(dot(v, _7340), 0.0);\n        result += (_7351 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5283 = tdh / at;\n    float _5287 = bdh / ab;\n    float _5299 = ((_5283 * _5283) + (_5287 * _5287)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5299) * _5299);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5479 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5558 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5558) * _5558);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5479);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5479));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4682 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4685 = _4682.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4685 * _4685, exp2((-9.27999973297119140625) * ndv)) * _4685) + _4682.y)) + _4682.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3992;\n    if (lv == 0)\n    {\n        _3992 = 0.0;\n    }\n    else\n    {\n        _3992 = res + 2.0;\n    }\n    float _4002;\n    if (lv == 0)\n    {\n        _4002 = 0.0;\n    }\n    else\n    {\n        _4002 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3992, _4002)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4048;\n    if (res > 64.5)\n    {\n        _4048 = 5.0;\n    }\n    else\n    {\n        _4048 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4063 = clamp(rough, 0.0, 1.0) * (_4048 - 1.0);\n    int _4070 = int(min(floor(_4063), _4048 - 2.0));\n    float _4075 = _4063 - float(_4070);\n    vec3 param = d;\n    vec2 _4079 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4070;\n    vec2 param_4 = _4079;\n    vec3 _4089 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4075 < 0.00200000009499490261077880859375)\n    {\n        return _4089;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4070 + 1;\n    vec2 param_8 = _4079;\n    return mix(_4089, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4075));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4160 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4167 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4174 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4180 = dot(bx.xyz, d);\n    float _4184 = dot(by.xyz, d);\n    float _4188 = dot(bz.xyz, d);\n    float _4194;\n    if (_4180 > 9.9999999747524270787835121154785e-07)\n    {\n        _4194 = (1.0 - _4160) / _4180;\n    }\n    else\n    {\n        float _4208;\n        if (_4180 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4208 = ((-1.0) - _4160) / _4180;\n        }\n        else\n        {\n            _4208 = 1000000015047466219876688855040.0;\n        }\n        _4194 = _4208;\n    }\n    float tx = _4194;\n    float _4225;\n    if (_4184 > 9.9999999747524270787835121154785e-07)\n    {\n        _4225 = (1.0 - _4167) / _4184;\n    }\n    else\n    {\n        float _4238;\n        if (_4184 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4238 = ((-1.0) - _4167) / _4184;\n        }\n        else\n        {\n            _4238 = 1000000015047466219876688855040.0;\n        }\n        _4225 = _4238;\n    }\n    float ty = _4225;\n    float _4254;\n    if (_4188 > 9.9999999747524270787835121154785e-07)\n    {\n        _4254 = (1.0 - _4174) / _4188;\n    }\n    else\n    {\n        float _4267;\n        if (_4188 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4267 = ((-1.0) - _4174) / _4188;\n        }\n        else\n        {\n            _4267 = 1000000015047466219876688855040.0;\n        }\n        _4254 = _4267;\n    }\n    float _4279 = tx;\n    float _4282 = (_4279 > 0.0) ? _4279 : 1000000015047466219876688855040.0;\n    tx = _4282;\n    float _4283 = ty;\n    float _4286 = (_4283 > 0.0) ? _4283 : 1000000015047466219876688855040.0;\n    ty = _4286;\n    float _4296 = min(_4282, min(_4286, (_4254 > 0.0) ? _4254 : 1000000015047466219876688855040.0));\n    if (_4296 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4312 = (fa_world_pos + (d * _4296)) - posw.xyz;\n    vec3 _4317;\n    if (dot(_4312, _4312) > 1.0000000133514319600180897396058e-10)\n    {\n        _4317 = normalize(_4312);\n    }\n    else\n    {\n        _4317 = d;\n    }\n    return _4317;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4363 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4363 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4391 = rough * rough;\n            float _4422 = 0.60000002384185791015625 * _4391;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4391)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4422, 0.0500000007450580596923828125 + _4422, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4391 * 0.60000002384185791015625));\n        }\n        outc = base * _4363;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4481 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4481 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4513 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4513 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5160;\n        if (L.aniso >= 0.0)\n        {\n            _5160 = L.b;\n        }\n        else\n        {\n            _5160 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5160, v), _5160), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5196 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5196.x) + (vec3(L.f90) * _5196.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5254 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5254.x) + _5254.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4724 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4724.x) + vec3(_4724.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5956 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5960 = fa_xm_origin(param_1);\n    vec2 _5966 = (uv * _5956) - vec2(0.5);\n    vec2 _5969 = fract(_5966);\n    vec2 _5972 = floor(_5966);\n    vec2 param_2 = _5956;\n    vec2 param_3 = _5960;\n    vec2 param_4 = _5972;\n    vec2 param_5 = _5956;\n    vec2 param_6 = _5960;\n    vec2 param_7 = _5972 + vec2(1.0, 0.0);\n    vec2 param_8 = _5956;\n    vec2 param_9 = _5960;\n    vec2 param_10 = _5972 + vec2(0.0, 1.0);\n    vec2 param_11 = _5956;\n    vec2 param_12 = _5960;\n    vec2 param_13 = _5972 + vec2(1.0);\n    vec3 _6014 = vec3(_5969.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6014), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6014), vec3(_5969.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6033 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6037 = clamp(lod, 0.0, _6033);\n    int _6041 = int(floor(_6037));\n    int param = _6041;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6051 = float(_6041);\n    float _6052 = _6037 - _6051;\n    bool _6054 = _6052 > 0.001000000047497451305389404296875;\n    bool _6061;\n    if (_6054)\n    {\n        _6061 = _6051 < _6033;\n    }\n    else\n    {\n        _6061 = _6054;\n    }\n    if (_6061)\n    {\n        int param_2 = _6041 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6052));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6087 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _6087.x) + (vec3(f90) * _6087.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _6115 = max(s.thickness, 0.0);\n    bool _6120 = _6115 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6120)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6115);\n    }\n    bool _6145 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6152;\n    if (!_6145)\n    {\n        _6152 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6152 = _6145;\n    }\n    if (_6152)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_6120)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6115);\n    }\n    vec4 _6187 = vec4(world, 1.0);\n    float _6192 = dot(fa_mesh_fs_params[28], _6187);\n    vec2 uv = vec2(0.5);\n    if (_6192 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6210 = vec2(dot(fa_mesh_fs_params[26], _6187), dot(fa_mesh_fs_params[27], _6187)) / vec2(_6192);\n        float _6218;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6218 = (_6210.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6218 = 0.5 - (_6210.y * 0.5);\n        }\n        uv = vec2((_6210.x * 0.5) + 0.5, _6218);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3284 = int(fa_shadows[25].x + 0.5);\n    float _3294 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3299 = _3284 > 0;\n    bool _3308;\n    if (_3299)\n    {\n        int param = _3284 - 1;\n        _3308 = _3294 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3308 = _3299;\n    }\n    if (_3308)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3314 = _3284 > 1;\n        bool _3321;\n        if (_3314)\n        {\n            _3321 = _3294 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3321 = _3314;\n        }\n        if (_3321)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3327 = _3284 > 2;\n        bool _3334;\n        if (_3327)\n        {\n            _3334 = _3294 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3334 = _3327;\n        }\n        if (_3334)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3340 = _3284 > 3;\n        bool _3347;\n        if (_3340)\n        {\n            _3347 = _3294 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3347 = _3340;\n        }\n        if (_3347)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _9206 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9206 = -_9206;\n    }\n    vec3 _8504 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9206, fa_world_tangent, fa_uv, fa_vertex_color, _8504, gl_FrontFacing);\n    Surface _8512 = fa_standard_surface(param_1);\n    vec3 _9237 = _8512.albedo;\n    float _9238 = _8512.alpha;\n    vec3 _9239 = _8512.normal;\n    float _9240 = _8512.metallic;\n    float _9241 = _8512.roughness;\n    float _9242 = _8512.occlusion;\n    vec3 _9243 = _8512.emission;\n    float _9244 = _8512.clearcoat;\n    float _9245 = _8512.clearcoat_roughness;\n    vec3 _9246 = _8512.sheen_color;\n    float _9247 = _8512.sheen_roughness;\n    float _9248 = _8512.anisotropy;\n    float _9249 = _8512.anisotropy_rotation;\n    float _9250 = _8512.specular;\n    float _9251 = _8512.ior;\n    vec3 _9252 = _8512.specular_color;\n    float _9253 = _8512.transmission;\n    float _9254 = _8512.thickness;\n    vec3 _9255 = _8512.attenuation_color;\n    float _9256 = _8512.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9206, fa_world_tangent, fa_uv, fa_vertex_color, _8504, gl_FrontFacing);\n    Surface param_3 = _8512;\n    surface(param_2, param_3);\n    _9237 = param_3.albedo;\n    _9238 = param_3.alpha;\n    _9239 = param_3.normal;\n    _9240 = param_3.metallic;\n    _9241 = param_3.roughness;\n    _9242 = param_3.occlusion;\n    _9243 = param_3.emission;\n    _9244 = param_3.clearcoat;\n    _9245 = param_3.clearcoat_roughness;\n    _9246 = param_3.sheen_color;\n    _9247 = param_3.sheen_roughness;\n    _9248 = param_3.anisotropy;\n    _9249 = param_3.anisotropy_rotation;\n    _9250 = param_3.specular;\n    _9251 = param_3.ior;\n    _9252 = param_3.specular_color;\n    _9253 = param_3.transmission;\n    _9254 = param_3.thickness;\n    _9255 = param_3.attenuation_color;\n    _9256 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9206;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9237 = param_6;\n    _9239 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9237;\n    }\n    else\n    {\n        vec3 _8552 = normalize(_9239);\n        float _8559 = clamp(_9240, 0.0, 1.0);\n        float _8563 = clamp(_9241, 0.0500000007450580596923828125, 1.0);\n        float _8567 = _8563 * _8563;\n        float _8571 = _8567 * _8567;\n        float _8576 = max(dot(_8552, _8504), 9.9999997473787516355514526367188e-05);\n        float _8582 = 1.0 - _8559;\n        float _8583 = clamp(_9253, 0.0, 1.0) * _8582;\n        vec3 _8592 = (_9237 * _8582) * (1.0 - _8583);\n        vec3 _8599 = mix(vec3(0.039999999105930328369140625), _9237, vec3(_8559));\n        vec3 f0 = _8599;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9206, fa_world_tangent, fa_uv, fa_vertex_color, _8504, gl_FrontFacing);\n        Surface param_9 = Surface(_9237, _9238, _9239, _9240, _9241, _9242, _9243, _9244, _9245, _9246, _9247, _9248, _9249, _9250, _9251, _9252, _9253, _9254, _9255, _9256);\n        vec3 param_10 = _8552;\n        vec3 param_11 = _8504;\n        float param_12 = _8559;\n        float param_13 = _8563;\n        vec3 param_14 = _8599;\n        FaLayers _8615 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8552;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8592) * _9242;\n        if (_8615.on)\n        {\n            lit *= _8615.base_scale;\n        }\n        int _8637 = fa_cl_ndir + fa_cl_local;\n        float _8702;\n        for (int ln = 0; ln < _8637; ln++)\n        {\n            int param_16 = ln;\n            int _8650 = fa_cl_light(param_16);\n            int param_17 = _8650;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8650;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9206;\n            LightSample _8666 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8674 = max(dot(_8552, _8666.direction), 0.0);\n            float _8680 = _8666.attenuation * _8666.shadow;\n            vec3 _8685 = normalize(_8666.direction + _8504);\n            float _8690 = max(dot(_8552, _8685), 0.0);\n            float _8695 = max(dot(_8504, _8685), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8615.on)\n                {\n                    _8702 = _8615.f90;\n                }\n                else\n                {\n                    _8702 = 1.0;\n                }\n                int param_21 = _8650;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8552;\n                vec3 param_24 = _8504;\n                vec3 param_25 = _8592;\n                vec3 param_26 = f0;\n                float param_27 = _8702;\n                float param_28 = _8563;\n                float param_29 = _8576;\n                float param_30 = _8680;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8615.on)\n                {\n                    FaLayers param_31 = _8615;\n                    vec3 param_32 = area;\n                    int param_33 = _8650;\n                    vec3 param_34 = _8552;\n                    vec3 param_35 = _8504;\n                    vec3 param_36 = _8666.direction;\n                    float param_37 = _8576;\n                    float param_38 = _8680;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8615.on)\n                {\n                    FaLayers param_39 = _8615;\n                    vec3 param_40 = _8592;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8552;\n                    vec3 param_43 = _8504;\n                    vec3 param_44 = _8666.direction;\n                    vec3 param_45 = _8685;\n                    float param_46 = _8674;\n                    float param_47 = _8576;\n                    float param_48 = _8690;\n                    float param_49 = _8695;\n                    float param_50 = _8567;\n                    float param_51 = _8571;\n                    int param_52 = _8650;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8680));\n                }\n                else\n                {\n                    float _8804 = ((_8690 * _8690) * (_8571 - 1.0)) + 1.0;\n                    int param_53 = _8650;\n                    lit += (((_8592 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8695, 5.0))) * (((_8571 / ((3.1415927410125732421875 * _8804) * _8804)) * (0.5 / max(mix((2.0 * _8674) * _8576, _8674 + _8576, _8567), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8674))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8674 * _8680));\n                }\n            }\n        }\n        if (_8615.on)\n        {\n            FaLayers param_54 = _8615;\n            vec3 param_55 = _8552;\n            vec3 param_56 = _8504;\n            vec3 param_57 = f0;\n            float param_58 = _8563;\n            float param_59 = _9242;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8552;\n            vec3 param_61 = _8504;\n            vec3 param_62 = f0;\n            float param_63 = _8563;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9242);\n        }\n        if (_8583 > 0.0)\n        {\n            float _8902;\n            if (_8615.on)\n            {\n                _8902 = _8615.f90;\n            }\n            else\n            {\n                _8902 = 1.0;\n            }\n            float _8910;\n            if (_8615.on)\n            {\n                _8910 = _8615.base_scale;\n            }\n            else\n            {\n                _8910 = 1.0;\n            }\n            Surface param_64 = Surface(_9237, _9238, _9239, _9240, _9241, _9242, _9243, _9244, _9245, _9246, _9247, _9248, _9249, _9250, _9251, _9252, _9253, _9254, _9255, _9256);\n            vec3 param_65 = _8552;\n            vec3 param_66 = _8504;\n            float param_67 = _8563;\n            vec3 param_68 = f0;\n            float param_69 = _8902;\n            float param_70 = _8910;\n            float param_71 = _8583;\n            float param_72 = fa_tr_blend;\n            vec3 _8934 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8934;\n        }\n        result = lit;\n    }\n    vec3 _8941 = result;\n    vec3 _8942 = _8941 + _9243;\n    result = _8942;\n    vec3 param_73 = _8942;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8951 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8958;\n    if (!_8951)\n    {\n        _8958 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8958 = _8951;\n    }\n    if (_8958)\n    {\n        vec3 _8967 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8973 = dot(_8967, fa_mesh_fs_params[9].xyz);\n        bool _8977 = fa_mesh_fs_params[9].w > 0.5;\n        float _8978;\n        if (_8977)\n        {\n            _8978 = _8973;\n        }\n        else\n        {\n            _8978 = length(_8967);\n        }\n        float _8990 = _8978 - fa_mesh_fs_params[8].x;\n        if (_8990 > 0.0)\n        {\n            float _8999 = fa_mesh_fs_params[7].w * _8990;\n            float tau = _8999 * _8999;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9015;\n                if (_8977)\n                {\n                    _9015 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8973);\n                }\n                else\n                {\n                    _9015 = fa_mesh_fs_params[0].y;\n                }\n                float _9036 = mix(_9015, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8978, 0.0, 1.0));\n                float _9040 = fa_world_pos.y - _9036;\n                float _9045 = _9036 - fa_mesh_fs_params[8].z;\n                float _9050 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9053 = _9045 <= 0.0;\n                bool _9054 = !_9053;\n                bool _9060;\n                if (_9054)\n                {\n                    _9060 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9060 = _9053;\n                }\n                float _9061;\n                if (_9060)\n                {\n                    _9061 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9061 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9045, 80.0));\n                }\n                bool _9088;\n                if (_9054)\n                {\n                    _9088 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9088 = _9053;\n                }\n                float _9089;\n                if (_9088)\n                {\n                    _9089 = fa_mesh_fs_params[8].y * _9045;\n                }\n                else\n                {\n                    _9089 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9045, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9114 = _9050 <= 0.0;\n                bool _9121;\n                if (!_9114)\n                {\n                    _9121 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9121 = _9114;\n                }\n                float _9122;\n                if (_9121)\n                {\n                    _9122 = fa_mesh_fs_params[8].y * _9050;\n                }\n                else\n                {\n                    _9122 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9050, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9149;\n                if (abs(_9040) < 0.001000000047497451305389404296875)\n                {\n                    _9149 = _9061;\n                }\n                else\n                {\n                    _9149 = (_9122 - _9089) / _9040;\n                }\n                tau += (_8990 * max(_9149, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9185 = 1.0 - fa_tr_blend;\n        result /= vec3(_9185);\n        _9238 *= _9185;\n    }\n    fa_frag_color = vec4(result, _9238);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_153",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_663",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2325",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_7429",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4825[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1601 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1608;\n    if (!_1601)\n    {\n        _1608 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1608 = _1601;\n    }\n    bool _1616;\n    if (!_1608)\n    {\n        _1616 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1616 = _1608;\n    }\n    bool _1623;\n    if (!_1616)\n    {\n        _1623 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1623 = _1616;\n    }\n    bool _1630;\n    if (!_1623)\n    {\n        _1630 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1630 = _1623;\n    }\n    if (_1630)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1640 = vec4(world_pos, 1.0);\n    float _1646 = dot(fa_mesh_fs_params[16], _1640);\n    if (!(_1646 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1668 = vec2(dot(fa_mesh_fs_params[14], _1640), dot(fa_mesh_fs_params[15], _1640)) / vec2(_1646);\n    int _1672 = int(fa_mesh_fs_params[18].x);\n    int _1676 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1676) + clamp(int(floor(((_1668.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1676 - 1)) * _1672)) + clamp(int(floor(((_1668.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1672 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1752 = fa_cluster_texel(param);\n    return ivec2(int(_1752.x), int(_1752.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _6292 = fa_cluster_lookup(param);\n    fa_cl_slot = _6292.x;\n    fa_cl_local = _6292.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _7481 = fa_linear_to_srgb(param);\n        c = _7481;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _7489 = fa_srgb_to_linear(param_1);\n            c = _7489;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _545;\n    if (i.front_facing)\n    {\n        _545 = i.world_normal;\n    }\n    else\n    {\n        _545 = -i.world_normal;\n    }\n    vec3 _569 = normalize(i.world_tangent.xyz - (_545 * dot(_545, i.world_tangent.xyz)));\n    vec3 _596 = normalize(((_569 * m.x) + ((cross(_545, _569) * i.world_tangent.w) * m.y)) + (_545 * m.z));\n    vec3 _599;\n    if (i.front_facing)\n    {\n        _599 = _596;\n    }\n    else\n    {\n        _599 = -_596;\n    }\n    return _599;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _7521 = fa_tex_fix(param_2, param_3);\n    vec4 _9812 = base_t;\n    _9812.x = _7521.x;\n    _9812.y = _7521.y;\n    _9812.z = _7521.z;\n    base_t = _9812;\n    vec4 _7535 = (_9812 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _9567 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _7569 = fa_tex_fix(param_6, param_7);\n        vec3 _7572 = (_7569 * 2.0) - vec3(1.0);\n        vec2 _7577 = _7572.xy * fa_mesh_fs_params[6].x;\n        vec3 _9820 = _7572;\n        _9820.x = _7577.x;\n        _9820.y = _7577.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _9820;\n        _9567 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _7607 = fa_tex_fix(param_12, param_13);\n    vec4 _9823 = mrt;\n    _9823.x = _7607.x;\n    _9823.y = _7607.y;\n    _9823.z = _7607.z;\n    mrt = _9823;\n    vec4 _7637 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _7637.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _7648 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _7680 = fa_tex_fix(param_20, param_21);\n    float _9572 = fa_mesh_fs_params[20].x;\n    float _9573 = fa_mesh_fs_params[20].y;\n    float _9576 = fa_mesh_fs_params[20].z;\n    float _9575 = fa_mesh_fs_params[21].w;\n    float _9578 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _9572 *= _7648.y;\n            _9573 *= _7648.z;\n            _9575 *= _7637.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _9576 *= mrt.x;\n            _9578 *= mrt.w;\n        }\n    }\n    return Surface(_7535.xyz, _7535.w, _9567, clamp(fa_mesh_fs_params[5].x * _7607.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _7607.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_7648.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _7680), _9572, _9573, fa_mesh_fs_params[21].xyz, _9575, _9576, fa_mesh_fs_params[20].w, _9578, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1832 = rect.zw - rect.xy;\n    vec2 _1836 = _1832 * atlas;\n    vec2 _1840 = ddx * _1836;\n    vec2 _1844 = ddy * _1836;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1832), clamp(0.5 * log2(max(max(dot(_1840, _1840), dot(_1844, _1844)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1877 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1884;\n    if (!_1877)\n    {\n        _1884 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1884 = _1877;\n    }\n    if (_1884)\n    {\n        return;\n    }\n    vec3 _1890 = dFdx(world_pos);\n    vec3 _1893 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1897 = fa_cluster_texel(param);\n    int _1901 = int(_1897.w);\n    if (_1901 < 1)\n    {\n        return;\n    }\n    int _1911 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1911;\n    vec4 _1915 = fa_light_texel(param_1);\n    vec2 _1918 = _1915.yz;\n    int _1922 = int(_1915.w);\n    int param_2 = _1911 + 1;\n    vec4 _1927 = fa_light_texel(param_2);\n    float _1928 = _1927.x;\n    int _1934 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1938 = int(_1897.z);\n    vec3 _2203;\n    for (int k = 0; k < _1901; k++)\n    {\n        int _1951 = _1938 + k;\n        int param_3 = _1922 + (_1951 >> 2);\n        int _1968 = (_1911 + 2) + (int(fa_light_texel(param_3)[_1951 & 3]) * 7);\n        int param_4 = _1968 + 6;\n        vec4 _1973 = fa_light_texel(param_4);\n        if (((int(_1973.w + 0.5) >> _1934) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1968;\n        vec4 _1988 = fa_light_texel(param_5);\n        int param_6 = _1968 + 1;\n        vec4 _1993 = fa_light_texel(param_6);\n        int param_7 = _1968 + 2;\n        vec4 _1998 = fa_light_texel(param_7);\n        vec3 _2001 = _1988.xyz;\n        float _2006 = dot(_2001, world_pos) + _1988.w;\n        vec3 _2008 = _1993.xyz;\n        float _2013 = dot(_2008, world_pos) + _1993.w;\n        vec3 _2015 = _1998.xyz;\n        float _2020 = dot(_2015, world_pos) + _1998.w;\n        bool _2025 = abs(_2006) > 0.5;\n        bool _2033;\n        if (!_2025)\n        {\n            _2033 = abs(_2013) > 0.5;\n        }\n        else\n        {\n            _2033 = _2025;\n        }\n        bool _2041;\n        if (!_2033)\n        {\n            _2041 = abs(_2020) > 0.5;\n        }\n        else\n        {\n            _2041 = _2033;\n        }\n        if (_2041)\n        {\n            continue;\n        }\n        float _2056 = clamp(dot(geo_normal, normalize(_2015)) * _1973.z, 0.0, 1.0);\n        if (_2056 <= 0.0)\n        {\n            continue;\n        }\n        float _2076 = (clamp((0.5 - abs(_2020)) * 10.0, 0.0, 1.0) * _2056) * _1973.x;\n        vec2 _2084 = vec2(_2006 + 0.5, 0.5 - _2013);\n        vec2 _2094 = vec2(dot(_2001, _1890), dot(_2008, _1890));\n        vec2 _2104 = vec2(dot(_2001, _1893), dot(_2008, _1893));\n        int param_8 = _1968 + 5;\n        vec4 _2109 = fa_light_texel(param_8);\n        int param_9 = _1968 + 3;\n        vec4 _2114 = fa_light_texel(param_9);\n        int param_10 = _1968 + 4;\n        vec4 _2119 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2109.xyz;\n        bool _2129 = _2114.z > _2114.x;\n        if (_2129)\n        {\n            vec4 param_11 = _2114;\n            vec2 param_12 = _2084;\n            vec2 param_13 = _1918;\n            vec2 param_14 = _2094;\n            vec2 param_15 = _2104;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1928 > 0.5) && (_1928 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2155 = fa_dc_to_linear(param_16);\n                vec4 _9655 = tx;\n                _9655.x = _2155.x;\n                _9655.y = _2155.y;\n                _9655.z = _2155.z;\n                tx = _9655;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2076 * tex_a) * _2109.w, 0.0, 1.0)));\n        if (_2119.z > _2119.x)\n        {\n            vec4 param_17 = _2119;\n            vec2 param_18 = _2084;\n            vec2 param_19 = _1918;\n            vec2 param_20 = _2094;\n            vec2 param_21 = _2104;\n            vec4 _2199 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1928 > 1.5)\n            {\n                vec3 param_22 = _2199.xyz;\n                vec3 _2209 = fa_dc_to_srgb(param_22);\n                _2203 = _2209;\n            }\n            else\n            {\n                _2203 = _2199.xyz;\n            }\n            vec3 _2218 = (_2203 * 2.0) - vec3(1.0);\n            vec2 _2223 = _2218.xy * _1973.y;\n            vec3 _2245 = (normalize(_2001) * _2223.x) + (normalize(_2008) * _2223.y);\n            vec3 _2248 = normalize(normal);\n            normal = normalize(mix(_2248, normalize((_2248 * max(_2218.z, 0.0500000007450580596923828125)) + (_2245 - (_2248 * dot(_2248, _2245)))), vec3(clamp(_2076 * (_2129 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4750 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4758 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4761 = int(_4750);\n    int _4764 = int(_4758);\n    float _4774 = _4758 - float(_4764);\n    int _4829 = (_4761 * 9) + _4764;\n    int _4849 = ((_4761 + 1) * 9) + _4764;\n    return mix(mix(_4825[_4829], _4825[_4829 + 1], _4774), mix(_4825[_4849], _4825[_4849 + 1], _4774), _4750 - float(_4761));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _9490 = false;\n    float _9491 = 1.0;\n    float _9492 = 1.0;\n    float _9493 = 1.0;\n    float _9494 = 0.0;\n    float _9495 = 0.0;\n    float _9496 = 0.0;\n    float _9497 = 0.0;\n    float _9499 = 1.0;\n    bool _9500 = false;\n    vec3 _9501 = vec3(0.0);\n    float _9502 = 1.0;\n    float _9503 = 1.0;\n    float _9504 = 1.0;\n    float _9505 = 0.0;\n    float _9506 = 0.0;\n    vec3 _9507 = vec3(1.0, 0.0, 0.0);\n    vec3 _9508 = vec3(0.0, 0.0, 1.0);\n    float _9509 = 1.0;\n    float _9510 = 1.0;\n    float _4900 = clamp(s.specular, 0.0, 1.0);\n    float _4904 = clamp(s.ior, 1.0, 3.0);\n    bool _4909 = (_4900 != 1.0) || (_4904 != 1.5);\n    bool _4918;\n    if (!_4909)\n    {\n        _4918 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4918 = _4909;\n    }\n    if (_4918)\n    {\n        float _4926 = (_4904 - 1.0) / (_4904 + 1.0);\n        f0 = mix(min(vec3(_4926 * _4926) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4900, s.albedo, vec3(metallic));\n        _9491 = mix(_4900, 1.0, metallic);\n        _9490 = true;\n    }\n    float _4953 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4953 > 0.0)\n    {\n        float _4961 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _9494 = _4953;\n        _9495 = _4961;\n        float _4968 = _4961 * _4961;\n        _9496 = _4968;\n        _9497 = _4968 * _4968;\n        float _4980 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _9499 = _4980;\n        _9492 = 1.0 - (_4953 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4980, 0.0, 1.0), 5.0))));\n        _9490 = true;\n    }\n    vec3 _4999 = max(s.sheen_color, vec3(0.0));\n    float _5008 = max(_4999.x, max(_4999.y, _4999.z));\n    if (_5008 > 0.0)\n    {\n        float _5016 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _9500 = true;\n        _9501 = _4999;\n        _9502 = _5016;\n        _9503 = _5016 * _5016;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _5016;\n        float _5033 = fa_sheen_albedo(param, param_1);\n        _9505 = _5033;\n        _9504 = 1.0 - min(_5008 * _5033, 1.0);\n        _9490 = true;\n    }\n    _9493 = _9492 * _9504;\n    float _5052 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_5052 != 0.0)\n    {\n        vec3 _5067 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _5067;\n        if (dot(_5067, _5067) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _5079 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_5079.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _5079.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _5079.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _5083 = t;\n        vec3 _5084 = normalize(_5083);\n        t = _5084;\n        vec3 _5109 = normalize((_5084 * cos(s.anisotropy_rotation)) + ((cross(n, _5084) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _9507 = _5109;\n        _9508 = cross(n, _5109);\n        float _5119 = roughness * roughness;\n        float _5125 = mix(_5119, 1.0, _5052 * _5052);\n        bool _5127 = _5052 > 0.0;\n        _9509 = _5127 ? _5125 : _5119;\n        _9510 = _5127 ? _5119 : _5125;\n        _9506 = _5052;\n        _9490 = true;\n    }\n    return FaLayers(_9490, _9491, _9492, _9493, _9494, _9495, _9496, _9497, i.world_normal, _9499, _9500, _9501, _9502, _9503, _9504, _9505, _9506, _9507, _9508, _9509, _9510);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3920 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3920;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4531 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4536 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4531 > 0.0005000000237487256526947021484375)\n    {\n        if (_4536)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4531;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4531;\n        }\n    }\n    bool _4587 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4587)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4618 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4618)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4536 || _4587) || _4618)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3940 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3943 = _3940.x;\n    float _3945 = _3940.z;\n    vec2 e = vec2(_3943, _3945);\n    if (_3940.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3945)) * ((_3943 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3943)) * ((_3945 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _7790 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _7795 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _7800 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _7805 = fa_light_texel(param_3);\n    bool _7808 = _7805.z < 0.5;\n    bool _7816;\n    if (!_7808)\n    {\n        _7816 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _7816 = _7808;\n    }\n    if (_7816)\n    {\n        return vec3(0.0);\n    }\n    float _7823 = max(_7790.w, 9.9999997473787516355514526367188e-05);\n    vec3 _7826 = _7795.xyz;\n    vec3 _7830 = _7790.xyz;\n    vec3 _7834 = (fa_world_pos - _7830) / vec3(_7823);\n    vec3 _7843 = min(_7834 + vec3(0.5), (_7826 - vec3(0.5)) - _7834);\n    float _7852 = min(_7843.x, min(_7843.y, _7843.z));\n    if (!(_7852 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _7867 = _7826 - vec3(1.0);\n    vec3 _7868 = clamp(_7834, vec3(0.0), _7867);\n    vec3 _7876 = min(floor(_7868), max(_7826 - vec3(2.0), vec3(0.0)));\n    vec3 _7880 = _7868 - _7876;\n    vec3 _7891 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _7823));\n    int _7896 = int(_7800.y + 0.5);\n    float _7901 = 0.3257350027561187744140625 * n.y;\n    float _7905 = 0.3257350027561187744140625 * n.z;\n    float _7909 = 0.3257350027561187744140625 * n.x;\n    float _7916 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _7923 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _7932 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _7939 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _7952 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _7959 = 8 + int(_7805.w);\n    float _7986;\n    float _7999;\n    float _8013;\n    for (int k = 0; k < _7959; k++)\n    {\n        float _7972 = float(k & 1);\n        float _7976 = float((k >> 1) & 1);\n        float _7980 = float((k >> 2) & 1);\n        if (_7972 > 0.5)\n        {\n            _7986 = _7880.x;\n        }\n        else\n        {\n            _7986 = 1.0 - _7880.x;\n        }\n        if (_7976 > 0.5)\n        {\n            _7999 = _7880.y;\n        }\n        else\n        {\n            _7999 = 1.0 - _7880.y;\n        }\n        if (_7980 > 0.5)\n        {\n            _8013 = _7880.z;\n        }\n        else\n        {\n            _8013 = 1.0 - _7880.z;\n        }\n        float _8023 = (_7986 * _7999) * _8013;\n        if (!(_8023 > 0.0))\n        {\n            continue;\n        }\n        vec3 _8036 = min(_7876 + vec3(_7972, _7976, _7980), _7867);\n        int _8056 = int(((_7800.x + _8036.x) + (_7795.x * (_8036.y + (_7795.y * _8036.z)))) + 0.5);\n        vec2 _8071 = vec2(float(_8056 % _7896) * 10.0, 1024.0 + (float(_8056 / _7896) * 11.0));\n        vec2 param_4 = _8071 + vec2(9.5, 10.5);\n        vec4 _8079 = fa_gi_fetch(param_4);\n        bool _8082 = _8079.y < 0.5;\n        bool _8091;\n        if (!_8082)\n        {\n            _8091 = _8079.x > _7805.y;\n        }\n        else\n        {\n            _8091 = _8082;\n        }\n        if (_8091)\n        {\n            continue;\n        }\n        vec3 _8103 = _7891 - (_7830 + (_8036 * _7823));\n        float _8106 = length(_8103);\n        vec3 _8112 = _8103 / vec3(max(_8106, 9.9999997473787516355514526367188e-05));\n        float _8122 = max(9.9999997473787516355514526367188e-05, (dot(-_8112, n) + 1.0) * 0.5);\n        float w = _8023 * (_8122 * _8122);\n        vec3 param_5 = _8112;\n        vec2 param_6 = (_8071 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _8141 = fa_gi_fetch(param_6);\n        float _8148 = _8106 / max(_7800.z, 9.9999997473787516355514526367188e-05);\n        float _8151 = _8141.x;\n        if (_8148 > _8151)\n        {\n            float _8164 = max(_8141.y - (_8151 * _8151), 0.0);\n            float _8169 = _8148 - _8151;\n            float _8178 = _8164 / max(_8164 + (_8169 * _8169), 9.9999999600419720025001879548654e-13);\n            w *= ((_8178 * _8178) * _8178);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _8071 + vec2(0.5, 10.5);\n        vec2 param_8 = _8071 + vec2(1.5, 10.5);\n        vec2 param_9 = _8071 + vec2(2.5, 10.5);\n        vec2 param_10 = _8071 + vec2(3.5, 10.5);\n        vec2 param_11 = _8071 + vec2(4.5, 10.5);\n        vec2 param_12 = _8071 + vec2(5.5, 10.5);\n        vec2 param_13 = _8071 + vec2(6.5, 10.5);\n        vec2 param_14 = _8071 + vec2(7.5, 10.5);\n        vec2 param_15 = _8071 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _7901)) + (fa_gi_fetch(param_9).xyz * _7905)) + (fa_gi_fetch(param_10).xyz * _7909)) + (fa_gi_fetch(param_11).xyz * _7916)) + (fa_gi_fetch(param_12).xyz * _7923)) + (fa_gi_fetch(param_13).xyz * _7932)) + (fa_gi_fetch(param_14).xyz * _7939)) + (fa_gi_fetch(param_15).xyz * _7952)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_7852 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _8303;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _8303 = _7805.x;\n    }\n    else\n    {\n        _8303 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_7800.w * _8303);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _8327 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _8332 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _8337 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _8337) && (k < 8); k++)\n    {\n        int param = _8332 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _8327;\n        vec3 _8362 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _8367 = param_3 * left;\n        acc += (_8362 * _8367);\n        left -= _8367;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _8396 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _8396;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _6262;\n    if (fa_lm.z > 0.5)\n    {\n        _6262 = 0.0;\n    }\n    else\n    {\n        _6262 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _6273 = _6262 < 1.0;\n    bool _6279;\n    if (_6273)\n    {\n        int param = li;\n        _6279 = fa_light_baked(param);\n    }\n    else\n    {\n        _6279 = _6273;\n    }\n    return _6279 ? _6262 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _850 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _863 = (c - (ru * hx)) - p;\n        vec3 _869 = ru * (2.0 * hx);\n        float _875 = max(dot(_869, _869), 9.9999999392252902907785028219223e-09);\n        float _879 = dot(_863, _869);\n        float t = clamp((-_879) / _875, 0.0, 1.0);\n        if (_850)\n        {\n            float _894 = dot(r, _869);\n            float _900 = _875 - (_894 * _894);\n            if (abs(_900) > (9.9999997473787516355514526367188e-06 * _875))\n            {\n                t = clamp(((dot(r, _863) * _894) - _879) / _900, 0.0, 1.0);\n            }\n        }\n        return (p + _863) + (_869 * t);\n    }\n    vec3 q = p;\n    float _932 = dot(r, axis);\n    bool _940;\n    if (_850)\n    {\n        _940 = abs(_932) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _940 = _850;\n    }\n    if (_940)\n    {\n        float _950 = dot(c - p, axis) / _932;\n        if (_950 > 0.0)\n        {\n            q = p + (r * _950);\n        }\n    }\n    vec3 _963 = q - c;\n    vec2 xy = vec2(dot(_963, ru), dot(_963, uu));\n    if (shape > 0.5)\n    {\n        float _978 = length(xy);\n        if (_978 > hx)\n        {\n            xy *= (hx / _978);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _611 = abs(d);\n    float _613 = _611.x;\n    float _615 = _611.y;\n    bool _616 = _613 >= _615;\n    bool _624;\n    if (_616)\n    {\n        _624 = _613 >= _611.z;\n    }\n    else\n    {\n        _624 = _616;\n    }\n    int _625;\n    if (_624)\n    {\n        _625 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _640;\n        if (_615 >= _611.z)\n        {\n            _640 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _640 = (d.z > 0.0) ? 4 : 5;\n        }\n        _625 = _640;\n    }\n    return _625;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _770 = dot(d, right);\n    float _774 = dot(d, up);\n    float _785;\n    if (((_770 * _770) + (_774 * _774)) > 1.0000000133514319600180897396058e-10)\n    {\n        _785 = atan(_774, _770) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _785 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_785 - floor(_785)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _1016 = fa_light_base(param);\n    bool _1020 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _1016;\n    vec4 _1024 = fa_light_texel(param_1);\n    int param_2 = _1016 + 1;\n    vec4 _1029 = fa_light_texel(param_2);\n    float _1032 = _1029.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _1044 = _1020 && (_1032 > 2.5);\n    fa_light_is_area = _1044;\n    bool _1046 = _1032 < 0.5;\n    vec3 l;\n    if (_1046)\n    {\n        l = normalize(_1024.xyz);\n        if (_1020)\n        {\n            int param_3 = _1016 + 6;\n            vec4 _1060 = fa_light_texel(param_3);\n            if (_1060.z > 0.5)\n            {\n                int param_4 = _1016 + 4;\n                vec4 _1070 = fa_light_texel(param_4);\n                int param_5 = _1016 + 5;\n                vec4 _1075 = fa_light_texel(param_5);\n                vec2 param_6 = _1060.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1070.xyz) * _1070.w, (-dot(world_pos, _1075.xyz)) * _1075.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1105 = _1024.xyz;\n        vec3 _1107 = _1105 - world_pos;\n        vec3 to_light = _1107;\n        float _1110 = length(_1107);\n        float reach = _1110;\n        bool front = true;\n        if (_1044)\n        {\n            int param_8 = _1016 + 7;\n            reach = max(_1110 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _1016 + 4;\n            vec4 _1134 = fa_light_texel(param_9);\n            int param_10 = _1016 + 5;\n            vec4 _1139 = fa_light_texel(param_10);\n            int param_11 = _1016 + 6;\n            vec4 _1144 = fa_light_texel(param_11);\n            float _1145 = _1144.w;\n            int param_12 = _1016 + 2;\n            vec3 _1152 = normalize(fa_light_texel(param_12).xyz);\n            bool _1154 = _1145 > 1.5;\n            bool _1162;\n            if (!_1154)\n            {\n                _1162 = dot(_1152, to_light) < 0.0;\n            }\n            else\n            {\n                _1162 = _1154;\n            }\n            front = _1162;\n            vec3 r = vec3(0.0);\n            vec3 _1171 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1175 = dot(n, n) > 0.5;\n            bool _1183;\n            if (_1175)\n            {\n                _1183 = dot(_1171, _1171) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1183 = _1175;\n            }\n            if (_1183)\n            {\n                r = reflect(-normalize(_1171), normalize(n));\n            }\n            vec3 param_13 = _1105;\n            vec3 param_14 = _1152;\n            vec3 param_15 = _1134.xyz;\n            vec3 param_16 = _1139.xyz;\n            float param_17 = _1134.w;\n            float param_18 = _1139.w;\n            float param_19 = _1145;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1219 = length(to_light);\n        dist = _1219;\n        l = to_light / vec3(max(_1219, 9.9999997473787516355514526367188e-05));\n        float _1233 = reach / max(_1024.w, 0.001000000047497451305389404296875);\n        float _1239 = clamp(1.0 - (_1233 * _1233), 0.0, 1.0);\n        float _1241;\n        if (front)\n        {\n            _1241 = _1239 * _1239;\n        }\n        else\n        {\n            _1241 = 0.0;\n        }\n        atten = _1241;\n        bool _1252 = _1032 < 2.5;\n        if ((_1032 > 1.5) && _1252)\n        {\n            int param_22 = _1016 + 2;\n            vec4 _1260 = fa_light_texel(param_22);\n            float _1270 = _1260.w;\n            int param_23 = _1016 + 3;\n            vec4 _1275 = fa_light_texel(param_23);\n            float _1276 = _1275.x;\n            float cos_inner = _1276;\n            if (_1276 > 1.5)\n            {\n                cos_inner = mix(_1270, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1270, cos_inner, dot(-l, normalize(_1260.xyz)));\n        }\n        if (_1020 && (_1032 < 1.5))\n        {\n            int param_24 = _1016 + 6;\n            vec4 _1300 = fa_light_texel(param_24);\n            if (_1300.z > 0.5)\n            {\n                vec3 _1308 = -to_light;\n                int param_25 = _1016 + 4;\n                int param_26 = _1016 + 5;\n                vec3 _1322 = fa_light_texel(param_25).xyz;\n                vec3 _1326 = fa_light_texel(param_26).xyz;\n                vec3 _1335 = vec3(dot(_1308, _1322), dot(_1308, _1326), dot(_1308, cross(_1322, _1326)));\n                vec3 param_27 = _1335;\n                int _1339 = fa_cube_face(param_27);\n                int param_28 = _1339;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1366 = vec2(dot(_1335, cross(param_29, param_30)), dot(_1335, param_30)) / vec2(max(dot(_1335, param_29), 9.9999997473787516355514526367188e-05));\n                int _1370 = _1339 / 3;\n                vec2 param_31 = _1300.xy + (vec2(float(_1339 - (_1370 * 3)), float(_1370)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1366.x), 0.5 - (0.5 * _1366.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _1016 + 7;\n            vec4 _1400 = fa_light_texel(param_33);\n            if (_1400.z > 0.5)\n            {\n                int param_34 = _1016 + 2;\n                int param_35 = _1016 + 4;\n                int param_36 = _1016 + 5;\n                vec2 param_37 = _1400.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_1020 && _1252)\n            {\n                int param_42 = _1016 + 6;\n                vec4 _1447 = fa_light_texel(param_42);\n                int param_43 = _1016 + 7;\n                vec4 _1452 = fa_light_texel(param_43);\n                bool _1455 = _1447.z > 0.5;\n                bool _1462;\n                if (!_1455)\n                {\n                    _1462 = _1452.z > 0.5;\n                }\n                else\n                {\n                    _1462 = _1455;\n                }\n                if (_1462)\n                {\n                    int param_44 = _1016 + 2;\n                    vec4 _1469 = fa_light_texel(param_44);\n                    vec3 _1473 = normalize(_1469.xyz);\n                    int param_45 = _1016 + 4;\n                    vec4 _1478 = fa_light_texel(param_45);\n                    int param_46 = _1016 + 5;\n                    vec4 _1483 = fa_light_texel(param_46);\n                    if (_1455)\n                    {\n                        vec3 _1491 = -to_light;\n                        float _1498 = _1469.w;\n                        float _1514 = 0.5 / max(dot(_1491, _1473) * (sqrt(max(1.0 - (_1498 * _1498), 0.0)) / max(_1498, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1447.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1491, _1478.xyz) * _1514), 0.5 - (dot(_1491, _1483.xyz) * _1514));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1452.z > 0.5)\n                    {\n                        vec2 param_49 = _1452.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1473;\n                        vec3 param_52 = _1478.xyz;\n                        vec3 param_53 = _1483.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _9478 = _1029.xyz * atten;\n    if (_1020)\n    {\n        _9478 *= fa_light_tint;\n    }\n    int _1583;\n    if (_1046)\n    {\n        _1583 = 0;\n    }\n    else\n    {\n        _1583 = ((_1032 > 1.5) && (_1032 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _9478, atten, 1.0, dist, _1583);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2315;\n    if (i == 0)\n    {\n        _2315 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2331;\n        if (i == 1)\n        {\n            _2331 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2339;\n            if (i == 2)\n            {\n                _2339 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2339 = fa_shadows[24].w;\n            }\n            _2331 = _2339;\n        }\n        _2315 = _2331;\n    }\n    return _2315;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2372 = fa_shadow_depth(param, param_1);\n    float _2376;\n    if (conv.x < 0.5)\n    {\n        _2376 = _2372;\n    }\n    else\n    {\n        _2376 = (conv.y * conv.z) / (conv.z - (_2372 * (conv.z - conv.y)));\n    }\n    return _2376;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2422 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2428 = vec2(cos(_2422), sin(_2422));\n    vec2 dir = _2428;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2437;\n        if (k < 0.0)\n        {\n            _2437 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2437 = k;\n        }\n        float _2456 = clamp((_2437 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2475 = sqrt((float(i) + 0.5) * 0.0625) * _2456;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2475));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2489 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2489 < (zr - (_2475 * plane)))\n            {\n                sum += _2489;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2517 = sum / cnt;\n        float _2527;\n        if (k < 0.0)\n        {\n            _2527 = (-k) / max(_2517, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2527 = k;\n        }\n        radius = clamp(((max(zr - _2517, 0.0) * unit) * _2527) / texel_m, 1.5, 16.0);\n        dir = _2428;\n    }\n    float lit = 0.0;\n    int _2553 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2553; i_1++)\n    {\n        float _2572 = sqrt((float(i_1) + 0.5) / float(_2553)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2572));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2572 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2553);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2618 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2623 = clamp(dot(n, l), 0.0, 1.0);\n    float _2629 = sqrt(1.0 - (_2623 * _2623));\n    float _2637 = min(_2629 / max(_2623, 0.20000000298023223876953125), 4.0);\n    float _2642;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2642 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2642 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2667 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2642 * _2629)), 1.0);\n    float _2674 = _2667.x;\n    bool _2677 = _2674 < fa_shadows[ci * 1 + 16].x;\n    bool _2686;\n    if (!_2677)\n    {\n        _2686 = _2674 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2686 = _2677;\n    }\n    bool _2695;\n    if (!_2686)\n    {\n        _2695 = _2667.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2695 = _2686;\n    }\n    bool _2704;\n    if (!_2695)\n    {\n        _2704 = _2667.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2704 = _2695;\n    }\n    bool _2711;\n    if (!_2704)\n    {\n        _2711 = _2667.z > 1.0;\n    }\n    else\n    {\n        _2711 = _2704;\n    }\n    if (_2711)\n    {\n        return -1.0;\n    }\n    float _2719;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2719 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2719 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2667.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2667.z - ((_2719 * (1.0 + (0.5 * _2637))) / _2618);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2618;\n    float param_5 = _2618 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2637, 3.0)) * 0.5) / _2618;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3097 = int(fa_shadows[25].x + 0.5);\n    if (_3097 < 1)\n    {\n        return 1.0;\n    }\n    float _3112 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3097 - 1;\n    if (_3112 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3124 = _3097 > 1;\n    bool _3131;\n    if (_3124)\n    {\n        _3131 = _3112 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3131 = _3124;\n    }\n    if (_3131)\n    {\n        ci = 1;\n    }\n    bool _3135 = _3097 > 2;\n    bool _3142;\n    if (_3135)\n    {\n        _3142 = _3112 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3142 = _3135;\n    }\n    if (_3142)\n    {\n        ci = 2;\n    }\n    bool _3146 = _3097 > 3;\n    bool _3153;\n    if (_3146)\n    {\n        _3153 = _3112 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3153 = _3146;\n    }\n    if (_3153)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3164 = min(_3097, 4);\n    float _3205;\n    for (int c = ci; c < _3164; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3184 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3184;\n            break;\n        }\n        if (_3184 < 0.0)\n        {\n            continue;\n        }\n        s = _3184;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3205 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3205 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3224 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3205, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_3112 - (fa_shadow_split_at(param_7) - _3224)) / _3224, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3256;\n        if ((ci + 1) < _3097)\n        {\n            _3256 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3256 = 1.0;\n        }\n        s = mix(s, _3256, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3361 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3367;\n    if (_3361)\n    {\n        _3367 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3367 = _3361;\n    }\n    if (_3367)\n    {\n        float _3381 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n        float _3384 = fwidth(_3381);\n        vec4 _3394 = vec4(fa_world_pos, 1.0);\n        float _3400 = dot(fa_mesh_fs_params[28], _3394);\n        if (_3400 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3419 = vec2(dot(fa_mesh_fs_params[26], _3394), dot(fa_mesh_fs_params[27], _3394)) / vec2(_3400);\n            float _3424 = (_3419.x * 0.5) + 0.5;\n            float _3428;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3428 = (_3419.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3428 = 0.5 - (_3419.y * 0.5);\n            }\n            bool _3444 = _3424 >= 0.0;\n            bool _3450;\n            if (_3444)\n            {\n                _3450 = _3424 < 1.0;\n            }\n            else\n            {\n                _3450 = _3444;\n            }\n            bool _3456;\n            if (_3450)\n            {\n                _3456 = _3428 >= 0.0;\n            }\n            else\n            {\n                _3456 = _3450;\n            }\n            bool _3462;\n            if (_3456)\n            {\n                _3462 = _3428 < 1.0;\n            }\n            else\n            {\n                _3462 = _3456;\n            }\n            if (_3462)\n            {\n                vec4 _3488 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3424, _3428) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                bool _3491 = _3488.w > 0.5;\n                bool _3507;\n                if (_3491)\n                {\n                    _3507 = abs(_3381 - _3488.x) <= (((0.00200000009499490261077880859375 * _3381) + 0.00999999977648258209228515625) + min(1.5 * _3384, 0.100000001490116119384765625 * _3381));\n                }\n                else\n                {\n                    _3507 = _3491;\n                }\n                if (_3507)\n                {\n                    float _3513;\n                    if (fa_mesh_fs_params[25].z > 0.5)\n                    {\n                        vec3 param = fa_world_pos;\n                        vec3 param_1 = n;\n                        vec3 param_2 = l;\n                        _3513 = min(_3488.y, fa_shadow_sun(param, param_1, param_2));\n                    }\n                    else\n                    {\n                        _3513 = _3488.y;\n                    }\n                    return _3513;\n                }\n            }\n        }\n    }\n    vec3 param_3 = fa_world_pos;\n    vec3 param_4 = n;\n    vec3 param_5 = l;\n    return fa_shadow_sun(param_3, param_4, param_5);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2777 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2784;\n    if (!_2777)\n    {\n        _2784 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2784 = _2777;\n    }\n    if (_2784)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2797 = fa_light_texel(param);\n    float _2798 = _2797.x;\n    if (_2798 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2807 = int(_2798 + 0.5);\n    int param_1 = _2807;\n    vec4 _2811 = fa_light_texel(param_1);\n    int param_2 = _2807 + 1;\n    vec4 _2816 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2819 = _2811.y;\n    if (_2819 > 0.0)\n    {\n        float _2836 = 1.0 - smoothstep(0.75 * _2819, _2819, length(world - fa_shadows[27].xyz));\n        fade = _2836;\n        if (_2836 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2811.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2860 = (_2807 + 2) + (face * 6);\n    int param_4 = _2860;\n    int param_5 = _2860 + 1;\n    int param_6 = _2860 + 3;\n    vec4 _2874 = fa_light_texel(param_6);\n    int param_7 = _2860 + 4;\n    vec4 _2879 = fa_light_texel(param_7);\n    int param_8 = _2860 + 5;\n    vec4 _2884 = fa_light_texel(param_8);\n    float _2896 = _2884.x * max(dot(_2874, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2901 = clamp(dot(n, l), 0.0, 1.0);\n    float _2924 = clamp(dot(n, _2874.xyz), -1.0, 1.0);\n    float _2943 = min(sqrt(1.0 - (_2924 * _2924)) / max(abs(dot(n, world - lpos)) / max(dot(_2874, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2946 = _2816.y;\n    float _2948;\n    if (_2946 > 0.0)\n    {\n        _2948 = _2946;\n    }\n    else\n    {\n        _2948 = 1.5 * _2896;\n    }\n    vec4 _2968 = vec4(world + (n * (_2948 * sqrt(1.0 - (_2901 * _2901)))), 1.0);\n    float _2972 = dot(_2874, _2968);\n    float _2975 = _2884.y;\n    if (_2972 < _2975)\n    {\n        return 1.0;\n    }\n    vec2 _2990 = vec2(dot(fa_light_texel(param_4), _2968), dot(fa_light_texel(param_5), _2968)) / vec2(_2972);\n    float _2992 = _2990.x;\n    bool _2995 = _2992 < _2879.x;\n    bool _3004;\n    if (!_2995)\n    {\n        _3004 = _2992 > _2879.z;\n    }\n    else\n    {\n        _3004 = _2995;\n    }\n    bool _3013;\n    if (!_3004)\n    {\n        _3013 = _2990.y < _2879.y;\n    }\n    else\n    {\n        _3013 = _3004;\n    }\n    bool _3022;\n    if (!_3013)\n    {\n        _3022 = _2990.y > _2879.w;\n    }\n    else\n    {\n        _3022 = _3013;\n    }\n    if (_3022)\n    {\n        return 1.0;\n    }\n    float _3028 = _2816.x;\n    float _3030;\n    if (_3028 > 0.0)\n    {\n        _3030 = _3028;\n    }\n    else\n    {\n        _3030 = 1.5 * _2896;\n    }\n    vec2 param_9 = _2990;\n    vec4 param_10 = _2879;\n    float param_11 = _2972 - (_3030 * (1.0 + (0.5 * _2943)));\n    float param_12 = _2896;\n    float param_13 = 1.0;\n    float param_14 = _2884.z * 0.25;\n    float param_15 = (_2896 * min(_2943, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2975, _2884.z);\n    int param_17 = int(_2811.z + 0.5);\n    float param_18 = _2811.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_local_rt(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _3542 = fa_mesh_fs_params[25].w > 0.5;\n    bool _3548;\n    if (_3542)\n    {\n        _3548 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3548 = _3542;\n    }\n    bool _3554;\n    if (_3548)\n    {\n        _3554 = fa_shadows[29].x > 0.5;\n    }\n    else\n    {\n        _3554 = _3548;\n    }\n    if (_3554)\n    {\n        int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n        vec4 _3566 = fa_light_texel(param);\n        float _3567 = _3566.z;\n        if (_3567 > 0.5)\n        {\n            float _3580 = dot(fa_mesh_fs_params[29].xyz, world) + fa_mesh_fs_params[29].w;\n            float _3583 = fwidth(_3580);\n            float _3587 = min(1.5 * _3583, 0.100000001490116119384765625 * _3580);\n            vec4 _3593 = vec4(world, 1.0);\n            float _3598 = dot(fa_mesh_fs_params[28], _3593);\n            if (_3598 > 9.9999997473787516355514526367188e-05)\n            {\n                vec2 _3615 = vec2(dot(fa_mesh_fs_params[26], _3593), dot(fa_mesh_fs_params[27], _3593)) / vec2(_3598);\n                float _3620 = (_3615.x * 0.5) + 0.5;\n                float _3624;\n                if (fa_mesh_fs_params[24].y > 0.5)\n                {\n                    _3624 = (_3615.y * 0.5) + 0.5;\n                }\n                else\n                {\n                    _3624 = 0.5 - (_3615.y * 0.5);\n                }\n                bool _3640 = _3620 >= 0.0;\n                bool _3646;\n                if (_3640)\n                {\n                    _3646 = _3620 < 1.0;\n                }\n                else\n                {\n                    _3646 = _3640;\n                }\n                bool _3652;\n                if (_3646)\n                {\n                    _3652 = _3624 >= 0.0;\n                }\n                else\n                {\n                    _3652 = _3646;\n                }\n                bool _3658;\n                if (_3652)\n                {\n                    _3658 = _3624 < 1.0;\n                }\n                else\n                {\n                    _3658 = _3652;\n                }\n                if (_3658)\n                {\n                    ivec2 _3675 = ivec2(fa_mesh_fs_params[24].zw) - ivec2(1);\n                    ivec2 _3676 = clamp(ivec2(vec2(_3620, _3624) * fa_mesh_fs_params[24].zw), ivec2(0), _3675);\n                    ivec2 _3688;\n                    ivec2 _3694;\n                    ivec2 _3701;\n                    float _3752;\n                    float _3773;\n                    for (int k = 0; k < 5; k++)\n                    {\n                        if (k == 0)\n                        {\n                            _3688 = ivec2(0);\n                        }\n                        else\n                        {\n                            if (k == 1)\n                            {\n                                _3694 = ivec2(1, 0);\n                            }\n                            else\n                            {\n                                if (k == 2)\n                                {\n                                    _3701 = ivec2(-1, 0);\n                                }\n                                else\n                                {\n                                    bvec2 _3712 = bvec2(k == 3);\n                                    _3701 = ivec2(_3712.x ? ivec2(0, 1).x : ivec2(0, -1).x, _3712.y ? ivec2(0, 1).y : ivec2(0, -1).y);\n                                }\n                                _3694 = _3701;\n                            }\n                            _3688 = _3694;\n                        }\n                        vec4 _3729 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(_3676 + _3688, ivec2(0), _3675), 0);\n                        bool _3732 = _3729.w > 0.5;\n                        bool _3746;\n                        if (_3732)\n                        {\n                            _3746 = abs(_3580 - _3729.x) <= (((0.00200000009499490261077880859375 * _3580) + 0.00999999977648258209228515625) + _3587);\n                        }\n                        else\n                        {\n                            _3746 = _3732;\n                        }\n                        if (_3746)\n                        {\n                            if (_3567 < 1.5)\n                            {\n                                _3752 = 1.0;\n                            }\n                            else\n                            {\n                                _3752 = (_3567 < 2.5) ? 256.0 : 65536.0;\n                            }\n                            float _3769 = mod(floor(_3729.z / _3752), 256.0) * 0.0039215688593685626983642578125;\n                            if (fa_mesh_fs_params[25].z > 0.5)\n                            {\n                                int param_1 = li;\n                                vec3 param_2 = lpos;\n                                vec3 param_3 = world;\n                                vec3 param_4 = n;\n                                vec3 param_5 = l;\n                                _3773 = min(_3769, fa_shadow_local(param_1, param_2, param_3, param_4, param_5));\n                            }\n                            else\n                            {\n                                _3773 = _3769;\n                            }\n                            return _3773;\n                        }\n                    }\n                }\n            }\n            float _3798;\n            if (fa_mesh_fs_params[25].z > 0.5)\n            {\n                int param_6 = li;\n                vec3 param_7 = lpos;\n                vec3 param_8 = world;\n                vec3 param_9 = n;\n                vec3 param_10 = l;\n                _3798 = fa_shadow_local(param_6, param_7, param_8, param_9, param_10);\n            }\n            else\n            {\n                _3798 = 1.0;\n            }\n            return _3798;\n        }\n    }\n    int param_11 = li;\n    vec3 param_12 = lpos;\n    vec3 param_13 = world;\n    vec3 param_14 = n;\n    vec3 param_15 = l;\n    return fa_shadow_local(param_11, param_12, param_13, param_14, param_15);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5643 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5650;\n    if (!_5643)\n    {\n        _5650 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5650 = _5643;\n    }\n    if (_5650)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5663 = fa_light_texel(param);\n    float _5664 = _5663.y;\n    float len = _5664;\n    if (_5664 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5676 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5685 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5676);\n    if (_5685 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5691 = len;\n    float _5694 = min(_5691, 0.89999997615814208984375 * dist);\n    len = _5694;\n    float _5699 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5676);\n    float _5704 = _5699 + (0.5 * _5694);\n    vec3 _5710 = world + (gn * _5699);\n    float _5712 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5773;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5727 = (float(k) + _5712) * 0.083333335816860198974609375;\n        vec3 _5735 = _5710 + (l * (_5727 * len));\n        vec4 _5741 = vec4(_5735, 1.0);\n        float _5746 = dot(fa_mesh_fs_params[28], _5741);\n        if (_5746 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5764 = vec2(dot(fa_mesh_fs_params[26], _5741), dot(fa_mesh_fs_params[27], _5741)) / vec2(_5746);\n        float _5768 = _5764.x * 0.5;\n        float _5769 = _5768 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5773 = (_5764.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5773 = 0.5 - (_5764.y * 0.5);\n        }\n        bool _5789 = _5769 < 0.0;\n        bool _5796;\n        if (!_5789)\n        {\n            _5796 = _5769 >= 1.0;\n        }\n        else\n        {\n            _5796 = _5789;\n        }\n        bool _5803;\n        if (!_5796)\n        {\n            _5803 = _5773 < 0.0;\n        }\n        else\n        {\n            _5803 = _5796;\n        }\n        bool _5810;\n        if (!_5803)\n        {\n            _5810 = _5773 >= 1.0;\n        }\n        else\n        {\n            _5810 = _5803;\n        }\n        if (_5810)\n        {\n            break;\n        }\n        vec4 _5834 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_5769, _5773) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5834.w < 0.5)\n        {\n            continue;\n        }\n        float _5852 = (dot(fa_mesh_fs_params[29].xyz, _5735) + fa_mesh_fs_params[29].w) - _5834.x;\n        if ((_5852 > _5699) && (_5852 < _5704))\n        {\n            occ = max(occ, (1.0 - (_5727 * _5727)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5769, 0.5 - _5768), min(_5773, 1.0 - _5773))));\n        }\n    }\n    return 1.0 - (occ * _5685);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _6318 = fa_baked_keep(param);\n    if (_6318 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _6344 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _9547 = _6344.color;\n    float _9548 = _6344.attenuation;\n    float _9549 = _6344.shadow;\n    bool _6347 = _6344.type == 0;\n    if (_6347 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _6344.direction;\n        float _6358 = fa_shadow_factor(param_5, param_6);\n        _9549 = _6358;\n        _9547 *= _6358;\n    }\n    else\n    {\n        bool _6369 = _6344.type != 0;\n        bool _6375;\n        if (_6369)\n        {\n            _6375 = _9548 > 0.0;\n        }\n        else\n        {\n            _6375 = _6369;\n        }\n        if (_6375)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _6344.direction;\n            float _6394 = fa_shadow_local_rt(param_9, param_10, param_11, param_12, param_13);\n            _9549 = _6394;\n            _9547 *= _6394;\n        }\n    }\n    bool _6404 = fa_mesh_fs_params[24].x > 0.5;\n    bool _6410;\n    if (_6404)\n    {\n        _6410 = _9548 > 0.0;\n    }\n    else\n    {\n        _6410 = _6404;\n    }\n    if (_6410)\n    {\n        float _6417;\n        if (_6347)\n        {\n            _6417 = 1000000000.0;\n        }\n        else\n        {\n            _6417 = _6344._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _6344.direction;\n        float param_18 = _6417;\n        float _6435 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _9549 *= _6435;\n        _9547 *= _6435;\n    }\n    float _6448 = _9548;\n    float _6449 = _6448 * _6318;\n    _9548 = _6449;\n    vec3 _6453 = _9547;\n    vec3 _6454 = _6453 * _6318;\n    _9547 = _6454;\n    return LightSample(_6344.direction, _6454, _6449, _9549, _6344._distance, _6344.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _6488 = v - (n * dot(v, n));\n    vec3 t = _6488;\n    float _6492 = dot(_6488, _6488);\n    float l2 = _6492;\n    if (_6492 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _6502;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _6502 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _6502 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _6502;\n        l2 = dot(_6502, _6502);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_oct_vertex(int j, vec3 pc, vec3 ex, vec3 ey)\n{\n    float _6889;\n    if ((j == 0) || (j == 7))\n    {\n        _6889 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6899;\n        if ((j == 3) || (j == 4))\n        {\n            _6899 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6899 = ((j == 1) || (j == 6)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6889 = _6899;\n    }\n    float _6920;\n    if ((j == 1) || (j == 2))\n    {\n        _6920 = 0.92387950420379638671875;\n    }\n    else\n    {\n        float _6929;\n        if ((j == 5) || (j == 6))\n        {\n            _6929 = -0.92387950420379638671875;\n        }\n        else\n        {\n            _6929 = ((j == 0) || (j == 3)) ? 0.3826834261417388916015625 : (-0.3826834261417388916015625);\n        }\n        _6920 = _6929;\n    }\n    return (pc + (ex * _6889)) + (ey * _6920);\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _6537 = dot(a, a);\n    float _6541 = dot(b, b);\n    if ((_6537 < 1.0000000195414813782625560981111e-24) || (_6541 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _6555 = a * inversesqrt(_6537);\n    vec3 _6560 = b * inversesqrt(_6541);\n    float _6564 = dot(_6555, _6560);\n    float _6567 = abs(_6564);\n    float g = (((((((((((0.0416471660137176513671875 * _6567) - 0.1924748718738555908203125) * _6567) + 0.4179156124591827392578125) * _6567) - 0.616057217121124267578125) * _6567) + 0.777722418308258056640625) * _6567) - 0.999542415142059326171875) * _6567) + 1.570791721343994140625;\n    if (_6564 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_6564 * _6564), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_6555, _6560) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _6624 = a.z > 0.0;\n    bool _6628 = b.z > 0.0;\n    if (_6624 && _6628)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_6624 != _6628)\n        {\n            vec3 _6663 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _6663.z = 0.0;\n            if (_6624)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _6663;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _6663;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _6663;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _6663;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _6712 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _6738 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _6764 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _6790 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _6712;\n    vec3 param_1 = _6738;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _6738;\n    vec3 param_7 = _6764;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _6764;\n    vec3 param_13 = _6790;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _6790;\n    vec3 param_19 = _6712;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nvec2 fa_area_forms(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    int _6958 = ((shape < 0.5) || (shape > 1.5)) ? 1 : 3;\n    vec2 sum = vec2(0.0);\n    int _6976;\n    for (int k = 0; k < (2 * _6958); k++)\n    {\n        bool _6973 = k >= _6958;\n        if (_6973)\n        {\n            _6976 = k - _6958;\n        }\n        else\n        {\n            _6976 = k;\n        }\n        vec3 p0 = (pc - ex) - ey;\n        vec3 p1 = (pc + ex) - ey;\n        vec3 p2 = (pc + ex) + ey;\n        vec3 p3 = (pc - ex) + ey;\n        if (_6958 == 3)\n        {\n            int param = 0;\n            vec3 param_1 = pc;\n            vec3 param_2 = ex;\n            vec3 param_3 = ey;\n            p0 = fa_oct_vertex(param, param_1, param_2, param_3);\n            int _7022 = 2 * _6976;\n            int param_4 = _7022 + 1;\n            vec3 param_5 = pc;\n            vec3 param_6 = ex;\n            vec3 param_7 = ey;\n            p1 = fa_oct_vertex(param_4, param_5, param_6, param_7);\n            int param_8 = _7022 + 2;\n            vec3 param_9 = pc;\n            vec3 param_10 = ex;\n            vec3 param_11 = ey;\n            p2 = fa_oct_vertex(param_8, param_9, param_10, param_11);\n            int param_12 = _7022 + 3;\n            vec3 param_13 = pc;\n            vec3 param_14 = ex;\n            vec3 param_15 = ey;\n            p3 = fa_oct_vertex(param_12, param_13, param_14, param_15);\n        }\n        bvec4 _7059 = bvec4(_6973);\n        vec4 param_16 = vec4(_7059.x ? m.x : vec4(1.0, 0.0, 0.0, 1.0).x, _7059.y ? m.y : vec4(1.0, 0.0, 0.0, 1.0).y, _7059.z ? m.z : vec4(1.0, 0.0, 0.0, 1.0).z, _7059.w ? m.w : vec4(1.0, 0.0, 0.0, 1.0).w);\n        vec3 param_17 = p0;\n        vec3 param_18 = p1;\n        vec3 param_19 = p2;\n        vec3 param_20 = p3;\n        float _7070 = fa_ltc_quad(param_16, param_17, param_18, param_19, param_20);\n        if (_6973)\n        {\n            vec2 _9795 = sum;\n            _9795.y = _9795.y + _7070;\n            sum = _9795;\n        }\n        else\n        {\n            vec2 _9798 = sum;\n            _9798.x = _9798.x + _7070;\n            sum = _9798;\n        }\n    }\n    return abs(sum);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _7094 = fa_light_base(param);\n    int param_1 = _7094;\n    int param_2 = _7094 + 1;\n    int param_3 = _7094 + 2;\n    int param_4 = _7094 + 4;\n    vec4 _7116 = fa_light_texel(param_4);\n    int param_5 = _7094 + 5;\n    vec4 _7121 = fa_light_texel(param_5);\n    int param_6 = _7094 + 6;\n    vec4 _7126 = fa_light_texel(param_6);\n    float _7127 = _7126.w;\n    vec3 _7132 = fa_light_texel(param_1).xyz - world_pos;\n    bool _7134 = _7127 < 1.5;\n    bool _7141;\n    if (_7134)\n    {\n        _7141 = dot(normalize(fa_light_texel(param_3).xyz), _7132) >= 0.0;\n    }\n    else\n    {\n        _7141 = _7134;\n    }\n    if (_7141)\n    {\n        return vec3(0.0);\n    }\n    bool _7150 = (_7127 > 0.5) && _7134;\n    float _7154 = _7150 ? 1.0539000034332275390625 : 1.0;\n    vec3 _7157 = _7116.xyz;\n    float _7159 = _7116.w;\n    vec3 _7165 = _7121.xyz;\n    float _7167 = _7121.w;\n    vec3 up = _7165 * (_7167 * _7154);\n    float _7173;\n    if (_7150)\n    {\n        _7173 = (3.1415927410125732421875 * _7159) * _7159;\n    }\n    else\n    {\n        _7173 = (4.0 * _7159) * _7167;\n    }\n    if (_7127 > 1.5)\n    {\n        vec3 _7199 = cross(_7157, -_7132);\n        vec3 perp = _7199;\n        float _7203 = dot(_7199, _7199);\n        vec3 _7206;\n        if (_7203 > 1.0000000133514319600180897396058e-10)\n        {\n            _7206 = perp * inversesqrt(_7203);\n        }\n        else\n        {\n            _7206 = _7165;\n        }\n        perp = _7206;\n        up = _7206 * _7167;\n    }\n    float _7227 = max(_7173, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _7237 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _7237;\n    vec3 param_10 = n;\n    vec3 param_11 = _7132;\n    vec3 param_12 = _7237;\n    vec3 param_13 = n;\n    vec3 param_14 = _7157 * (_7159 * _7154);\n    vec3 param_15 = _7237;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    float param_18 = roughness;\n    float param_19 = ndv;\n    vec2 _7268 = fa_ltc_uv(param_18, param_19) * 64.0;\n    vec2 param_20 = _7268;\n    vec2 param_21 = _7268 + vec2(64.0, 0.0);\n    vec4 _7278 = fa_atlas_fetch(param_21);\n    vec4 param_22 = fa_atlas_fetch(param_20);\n    float param_23 = _7127;\n    vec3 param_24 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_25 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_26 = fa_ltc_local(param_15, param_16, param_17);\n    vec2 _7290 = fa_area_forms(param_22, param_23, param_24, param_25, param_26);\n    return (((diffuse_color * _7290.x) + (((f0 * _7278.x) + ((vec3(f90) - f0) * _7278.y)) * _7290.y)) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_7132, _7132)) + _7227) / _7227) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _5380 = 1.0 / alpha;\n    return ((2.0 + _5380) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _5380)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _5415 = max(dot(L.nc, l), 0.0);\n    float _5421 = max(dot(L.nc, h), 0.0);\n    float _5430 = ((_5421 * _5421) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _5430) * _5430)) * (0.5 / max(mix((2.0 * _5415) * L.coat_ndv, _5415 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _5415)) * _5415;\n}\n\nvec3 fa_area_layers(FaLayers L, vec3 base, int li, vec3 n, vec3 v, vec3 l, float ndv, float window)\n{\n    float _7327;\n    if (L.sheen_on)\n    {\n        _7327 = L.sheen_scale;\n    }\n    else\n    {\n        _7327 = 1.0;\n    }\n    vec3 result = base * (L.keep * _7327);\n    vec3 _7340 = normalize(l + v);\n    int param = li;\n    vec3 _7351 = fa_light_rgb(param) * window;\n    if (L.sheen_on)\n    {\n        float _7360 = max(dot(n, l), 0.0);\n        float param_1 = L.sheen_alpha;\n        float param_2 = max(dot(n, _7340), 0.0);\n        float param_3 = _7360;\n        float param_4 = ndv;\n        result += ((L.sheen * _7351) * (((((fa_d_charlie(param_1, param_2) * fa_v_ashikhmin(param_3, param_4)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _7360)) * _7360) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_5 = L;\n        vec3 param_6 = l;\n        vec3 param_7 = _7340;\n        float param_8 = max(dot(v, _7340), 0.0);\n        result += (_7351 * fa_layers_coat(param_5, param_6, param_7, param_8));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _5283 = tdh / at;\n    float _5287 = bdh / ab;\n    float _5299 = ((_5283 * _5283) + (_5287 * _5287)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _5299) * _5299);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _5479 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5558 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5558) * _5558);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _5479);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _5479));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4682 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4685 = _4682.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4685 * _4685, exp2((-9.27999973297119140625) * ndv)) * _4685) + _4682.y)) + _4682.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3992;\n    if (lv == 0)\n    {\n        _3992 = 0.0;\n    }\n    else\n    {\n        _3992 = res + 2.0;\n    }\n    float _4002;\n    if (lv == 0)\n    {\n        _4002 = 0.0;\n    }\n    else\n    {\n        _4002 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3992, _4002)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _4048;\n    if (res > 64.5)\n    {\n        _4048 = 5.0;\n    }\n    else\n    {\n        _4048 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _4063 = clamp(rough, 0.0, 1.0) * (_4048 - 1.0);\n    int _4070 = int(min(floor(_4063), _4048 - 2.0));\n    float _4075 = _4063 - float(_4070);\n    vec3 param = d;\n    vec2 _4079 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _4070;\n    vec2 param_4 = _4079;\n    vec3 _4089 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_4075 < 0.00200000009499490261077880859375)\n    {\n        return _4089;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _4070 + 1;\n    vec2 param_8 = _4079;\n    return mix(_4089, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_4075));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _4160 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _4167 = dot(by.xyz, fa_world_pos) + by.w;\n    float _4174 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _4180 = dot(bx.xyz, d);\n    float _4184 = dot(by.xyz, d);\n    float _4188 = dot(bz.xyz, d);\n    float _4194;\n    if (_4180 > 9.9999999747524270787835121154785e-07)\n    {\n        _4194 = (1.0 - _4160) / _4180;\n    }\n    else\n    {\n        float _4208;\n        if (_4180 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4208 = ((-1.0) - _4160) / _4180;\n        }\n        else\n        {\n            _4208 = 1000000015047466219876688855040.0;\n        }\n        _4194 = _4208;\n    }\n    float tx = _4194;\n    float _4225;\n    if (_4184 > 9.9999999747524270787835121154785e-07)\n    {\n        _4225 = (1.0 - _4167) / _4184;\n    }\n    else\n    {\n        float _4238;\n        if (_4184 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4238 = ((-1.0) - _4167) / _4184;\n        }\n        else\n        {\n            _4238 = 1000000015047466219876688855040.0;\n        }\n        _4225 = _4238;\n    }\n    float ty = _4225;\n    float _4254;\n    if (_4188 > 9.9999999747524270787835121154785e-07)\n    {\n        _4254 = (1.0 - _4174) / _4188;\n    }\n    else\n    {\n        float _4267;\n        if (_4188 < (-9.9999999747524270787835121154785e-07))\n        {\n            _4267 = ((-1.0) - _4174) / _4188;\n        }\n        else\n        {\n            _4267 = 1000000015047466219876688855040.0;\n        }\n        _4254 = _4267;\n    }\n    float _4279 = tx;\n    float _4282 = (_4279 > 0.0) ? _4279 : 1000000015047466219876688855040.0;\n    tx = _4282;\n    float _4283 = ty;\n    float _4286 = (_4283 > 0.0) ? _4283 : 1000000015047466219876688855040.0;\n    ty = _4286;\n    float _4296 = min(_4282, min(_4286, (_4254 > 0.0) ? _4254 : 1000000015047466219876688855040.0));\n    if (_4296 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _4312 = (fa_world_pos + (d * _4296)) - posw.xyz;\n    vec3 _4317;\n    if (dot(_4312, _4312) > 1.0000000133514319600180897396058e-10)\n    {\n        _4317 = normalize(_4312);\n    }\n    else\n    {\n        _4317 = d;\n    }\n    return _4317;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _4363 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_4363 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _4391 = rough * rough;\n            float _4422 = 0.60000002384185791015625 * _4391;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _4391)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _4422, 0.0500000007450580596923828125 + _4422, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_4391 * 0.60000002384185791015625));\n        }\n        outc = base * _4363;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _4481 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_4481 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4513 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4513 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _5160;\n        if (L.aniso >= 0.0)\n        {\n            _5160 = L.b;\n        }\n        else\n        {\n            _5160 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_5160, v), _5160), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _5196 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _5196.x) + (vec3(L.f90) * _5196.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _5254 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _5254.x) + _5254.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4724 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4724.x) + vec3(_4724.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(float(1 << k))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _5956 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _5960 = fa_xm_origin(param_1);\n    vec2 _5966 = (uv * _5956) - vec2(0.5);\n    vec2 _5969 = fract(_5966);\n    vec2 _5972 = floor(_5966);\n    vec2 param_2 = _5956;\n    vec2 param_3 = _5960;\n    vec2 param_4 = _5972;\n    vec2 param_5 = _5956;\n    vec2 param_6 = _5960;\n    vec2 param_7 = _5972 + vec2(1.0, 0.0);\n    vec2 param_8 = _5956;\n    vec2 param_9 = _5960;\n    vec2 param_10 = _5972 + vec2(0.0, 1.0);\n    vec2 param_11 = _5956;\n    vec2 param_12 = _5960;\n    vec2 param_13 = _5972 + vec2(1.0);\n    vec3 _6014 = vec3(_5969.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _6014), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _6014), vec3(_5969.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _6033 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _6037 = clamp(lod, 0.0, _6033);\n    int _6041 = int(floor(_6037));\n    int param = _6041;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _6051 = float(_6041);\n    float _6052 = _6037 - _6051;\n    bool _6054 = _6052 > 0.001000000047497451305389404296875;\n    bool _6061;\n    if (_6054)\n    {\n        _6061 = _6051 < _6033;\n    }\n    else\n    {\n        _6061 = _6054;\n    }\n    if (_6061)\n    {\n        int param_2 = _6041 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_6052));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _6087 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _6087.x) + (vec3(f90) * _6087.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _6115 = max(s.thickness, 0.0);\n    bool _6120 = _6115 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _6120)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _6115);\n    }\n    bool _6145 = fa_mesh_fs_params[30].w > 1.5;\n    bool _6152;\n    if (!_6145)\n    {\n        _6152 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _6152 = _6145;\n    }\n    if (_6152)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_6120)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _6115);\n    }\n    vec4 _6187 = vec4(world, 1.0);\n    float _6192 = dot(fa_mesh_fs_params[28], _6187);\n    vec2 uv = vec2(0.5);\n    if (_6192 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _6210 = vec2(dot(fa_mesh_fs_params[26], _6187), dot(fa_mesh_fs_params[27], _6187)) / vec2(_6192);\n        float _6218;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _6218 = (_6210.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _6218 = 0.5 - (_6210.y * 0.5);\n        }\n        uv = vec2((_6210.x * 0.5) + 0.5, _6218);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3284 = int(fa_shadows[25].x + 0.5);\n    float _3294 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3299 = _3284 > 0;\n    bool _3308;\n    if (_3299)\n    {\n        int param = _3284 - 1;\n        _3308 = _3294 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3308 = _3299;\n    }\n    if (_3308)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3314 = _3284 > 1;\n        bool _3321;\n        if (_3314)\n        {\n            _3321 = _3294 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3321 = _3314;\n        }\n        if (_3321)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3327 = _3284 > 2;\n        bool _3334;\n        if (_3327)\n        {\n            _3334 = _3294 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3334 = _3327;\n        }\n        if (_3334)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3340 = _3284 > 3;\n        bool _3347;\n        if (_3340)\n        {\n            _3347 = _3294 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3347 = _3340;\n        }\n        if (_3347)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _9206 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _9206 = -_9206;\n    }\n    vec3 _8504 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _9206, fa_world_tangent, fa_uv, fa_vertex_color, _8504, gl_FrontFacing);\n    Surface _8512 = fa_standard_surface(param_1);\n    vec3 _9237 = _8512.albedo;\n    float _9238 = _8512.alpha;\n    vec3 _9239 = _8512.normal;\n    float _9240 = _8512.metallic;\n    float _9241 = _8512.roughness;\n    float _9242 = _8512.occlusion;\n    vec3 _9243 = _8512.emission;\n    float _9244 = _8512.clearcoat;\n    float _9245 = _8512.clearcoat_roughness;\n    vec3 _9246 = _8512.sheen_color;\n    float _9247 = _8512.sheen_roughness;\n    float _9248 = _8512.anisotropy;\n    float _9249 = _8512.anisotropy_rotation;\n    float _9250 = _8512.specular;\n    float _9251 = _8512.ior;\n    vec3 _9252 = _8512.specular_color;\n    float _9253 = _8512.transmission;\n    float _9254 = _8512.thickness;\n    vec3 _9255 = _8512.attenuation_color;\n    float _9256 = _8512.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _9206, fa_world_tangent, fa_uv, fa_vertex_color, _8504, gl_FrontFacing);\n    Surface param_3 = _8512;\n    surface(param_2, param_3);\n    _9237 = param_3.albedo;\n    _9238 = param_3.alpha;\n    _9239 = param_3.normal;\n    _9240 = param_3.metallic;\n    _9241 = param_3.roughness;\n    _9242 = param_3.occlusion;\n    _9243 = param_3.emission;\n    _9244 = param_3.clearcoat;\n    _9245 = param_3.clearcoat_roughness;\n    _9246 = param_3.sheen_color;\n    _9247 = param_3.sheen_roughness;\n    _9248 = param_3.anisotropy;\n    _9249 = param_3.anisotropy_rotation;\n    _9250 = param_3.specular;\n    _9251 = param_3.ior;\n    _9252 = param_3.specular_color;\n    _9253 = param_3.transmission;\n    _9254 = param_3.thickness;\n    _9255 = param_3.attenuation_color;\n    _9256 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _9206;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _9237 = param_6;\n    _9239 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _9237;\n    }\n    else\n    {\n        vec3 _8552 = normalize(_9239);\n        float _8559 = clamp(_9240, 0.0, 1.0);\n        float _8563 = clamp(_9241, 0.0500000007450580596923828125, 1.0);\n        float _8567 = _8563 * _8563;\n        float _8571 = _8567 * _8567;\n        float _8576 = max(dot(_8552, _8504), 9.9999997473787516355514526367188e-05);\n        float _8582 = 1.0 - _8559;\n        float _8583 = clamp(_9253, 0.0, 1.0) * _8582;\n        vec3 _8592 = (_9237 * _8582) * (1.0 - _8583);\n        vec3 _8599 = mix(vec3(0.039999999105930328369140625), _9237, vec3(_8559));\n        vec3 f0 = _8599;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _9206, fa_world_tangent, fa_uv, fa_vertex_color, _8504, gl_FrontFacing);\n        Surface param_9 = Surface(_9237, _9238, _9239, _9240, _9241, _9242, _9243, _9244, _9245, _9246, _9247, _9248, _9249, _9250, _9251, _9252, _9253, _9254, _9255, _9256);\n        vec3 param_10 = _8552;\n        vec3 param_11 = _8504;\n        float param_12 = _8559;\n        float param_13 = _8563;\n        vec3 param_14 = _8599;\n        FaLayers _8615 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _8552;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _8592) * _9242;\n        if (_8615.on)\n        {\n            lit *= _8615.base_scale;\n        }\n        int _8637 = fa_cl_ndir + fa_cl_local;\n        float _8702;\n        for (int ln = 0; ln < _8637; ln++)\n        {\n            int param_16 = ln;\n            int _8650 = fa_cl_light(param_16);\n            int param_17 = _8650;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _8650;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _9206;\n            LightSample _8666 = fa_light_shadowed(param_18, param_19, param_20);\n            float _8674 = max(dot(_8552, _8666.direction), 0.0);\n            float _8680 = _8666.attenuation * _8666.shadow;\n            vec3 _8685 = normalize(_8666.direction + _8504);\n            float _8690 = max(dot(_8552, _8685), 0.0);\n            float _8695 = max(dot(_8504, _8685), 0.0);\n            if (fa_light_is_area)\n            {\n                if (_8615.on)\n                {\n                    _8702 = _8615.f90;\n                }\n                else\n                {\n                    _8702 = 1.0;\n                }\n                int param_21 = _8650;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _8552;\n                vec3 param_24 = _8504;\n                vec3 param_25 = _8592;\n                vec3 param_26 = f0;\n                float param_27 = _8702;\n                float param_28 = _8563;\n                float param_29 = _8576;\n                float param_30 = _8680;\n                vec3 area = fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n                if (_8615.on)\n                {\n                    FaLayers param_31 = _8615;\n                    vec3 param_32 = area;\n                    int param_33 = _8650;\n                    vec3 param_34 = _8552;\n                    vec3 param_35 = _8504;\n                    vec3 param_36 = _8666.direction;\n                    float param_37 = _8576;\n                    float param_38 = _8680;\n                    area = fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38);\n                }\n                lit += area;\n            }\n            else\n            {\n                if (_8615.on)\n                {\n                    FaLayers param_39 = _8615;\n                    vec3 param_40 = _8592;\n                    vec3 param_41 = f0;\n                    vec3 param_42 = _8552;\n                    vec3 param_43 = _8504;\n                    vec3 param_44 = _8666.direction;\n                    vec3 param_45 = _8685;\n                    float param_46 = _8674;\n                    float param_47 = _8576;\n                    float param_48 = _8690;\n                    float param_49 = _8695;\n                    float param_50 = _8567;\n                    float param_51 = _8571;\n                    int param_52 = _8650;\n                    lit += (fa_layers_light(param_39, param_40, param_41, param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51) * ((fa_light_rgb(param_52) * fa_light_tint) * _8680));\n                }\n                else\n                {\n                    float _8804 = ((_8690 * _8690) * (_8571 - 1.0)) + 1.0;\n                    int param_53 = _8650;\n                    lit += (((_8592 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _8695, 5.0))) * (((_8571 / ((3.1415927410125732421875 * _8804) * _8804)) * (0.5 / max(mix((2.0 * _8674) * _8576, _8674 + _8576, _8567), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _8674))) * (fa_light_rgb(param_53) * fa_light_tint)) * (_8674 * _8680));\n                }\n            }\n        }\n        if (_8615.on)\n        {\n            FaLayers param_54 = _8615;\n            vec3 param_55 = _8552;\n            vec3 param_56 = _8504;\n            vec3 param_57 = f0;\n            float param_58 = _8563;\n            float param_59 = _9242;\n            lit += fa_layers_ibl(param_54, param_55, param_56, param_57, param_58, param_59);\n        }\n        else\n        {\n            vec3 param_60 = _8552;\n            vec3 param_61 = _8504;\n            vec3 param_62 = f0;\n            float param_63 = _8563;\n            lit += (fa_sky_reflection(param_60, param_61, param_62, param_63) * _9242);\n        }\n        if (_8583 > 0.0)\n        {\n            float _8902;\n            if (_8615.on)\n            {\n                _8902 = _8615.f90;\n            }\n            else\n            {\n                _8902 = 1.0;\n            }\n            float _8910;\n            if (_8615.on)\n            {\n                _8910 = _8615.base_scale;\n            }\n            else\n            {\n                _8910 = 1.0;\n            }\n            Surface param_64 = Surface(_9237, _9238, _9239, _9240, _9241, _9242, _9243, _9244, _9245, _9246, _9247, _9248, _9249, _9250, _9251, _9252, _9253, _9254, _9255, _9256);\n            vec3 param_65 = _8552;\n            vec3 param_66 = _8504;\n            float param_67 = _8563;\n            vec3 param_68 = f0;\n            float param_69 = _8902;\n            float param_70 = _8910;\n            float param_71 = _8583;\n            float param_72 = fa_tr_blend;\n            vec3 _8934 = fa_transmitted(param_64, param_65, param_66, param_67, param_68, param_69, param_70, param_71, param_72);\n            fa_tr_blend = param_72;\n            lit += _8934;\n        }\n        result = lit;\n    }\n    vec3 _8941 = result;\n    vec3 _8942 = _8941 + _9243;\n    result = _8942;\n    vec3 param_73 = _8942;\n    vec3 param_74 = fa_world_pos;\n    result = fa_shadow_debug(param_73, param_74);\n    bool _8951 = fa_mesh_fs_params[7].w > 0.0;\n    bool _8958;\n    if (!_8951)\n    {\n        _8958 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _8958 = _8951;\n    }\n    if (_8958)\n    {\n        vec3 _8967 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _8973 = dot(_8967, fa_mesh_fs_params[9].xyz);\n        bool _8977 = fa_mesh_fs_params[9].w > 0.5;\n        float _8978;\n        if (_8977)\n        {\n            _8978 = _8973;\n        }\n        else\n        {\n            _8978 = length(_8967);\n        }\n        float _8990 = _8978 - fa_mesh_fs_params[8].x;\n        if (_8990 > 0.0)\n        {\n            float _8999 = fa_mesh_fs_params[7].w * _8990;\n            float tau = _8999 * _8999;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _9015;\n                if (_8977)\n                {\n                    _9015 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _8973);\n                }\n                else\n                {\n                    _9015 = fa_mesh_fs_params[0].y;\n                }\n                float _9036 = mix(_9015, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _8978, 0.0, 1.0));\n                float _9040 = fa_world_pos.y - _9036;\n                float _9045 = _9036 - fa_mesh_fs_params[8].z;\n                float _9050 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _9053 = _9045 <= 0.0;\n                bool _9054 = !_9053;\n                bool _9060;\n                if (_9054)\n                {\n                    _9060 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9060 = _9053;\n                }\n                float _9061;\n                if (_9060)\n                {\n                    _9061 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _9061 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _9045, 80.0));\n                }\n                bool _9088;\n                if (_9054)\n                {\n                    _9088 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9088 = _9053;\n                }\n                float _9089;\n                if (_9088)\n                {\n                    _9089 = fa_mesh_fs_params[8].y * _9045;\n                }\n                else\n                {\n                    _9089 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9045, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _9114 = _9050 <= 0.0;\n                bool _9121;\n                if (!_9114)\n                {\n                    _9121 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _9121 = _9114;\n                }\n                float _9122;\n                if (_9121)\n                {\n                    _9122 = fa_mesh_fs_params[8].y * _9050;\n                }\n                else\n                {\n                    _9122 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _9050, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _9149;\n                if (abs(_9040) < 0.001000000047497451305389404296875)\n                {\n                    _9149 = _9061;\n                }\n                else\n                {\n                    _9149 = (_9122 - _9089) / _9040;\n                }\n                tau += (_8990 * max(_9149, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _9185 = 1.0 - fa_tr_blend;\n        result /= vec3(_9185);\n        _9238 *= _9185;\n    }\n    fa_frag_color = vec4(result, _9238);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_158",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_205",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_663",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          },
          {
            "slot": 7,
            "stage": "fragment",
            "size": 480,
            "struct_name": "fa_shadows",
            "inst_name": "_2325",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_7429",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 1,
              "stage": "fragment",
              "name": "fa_shadow_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 14,
              "stage": "fragment",
              "name": "fa_probe_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 24,
              "stage": "fragment",
              "name": "fa_light_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          },
          {
            "texture": {
              "slot": 25,
              "stage": "fragment",
              "name": "fa_light_atlas",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 26,
              "stage": "fragment",
              "name": "fa_lightmap",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 27,
              "stage": "fragment",
              "name": "fa_decal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 28,
              "stage": "fragment",
              "name": "fa_screen_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_shadow_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_smp",
            "sampler_type": "filtering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_light_tex_fa_shadow_smp",
            "view_name": "fa_light_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 24,
            "sampler_slot": 1,
            "glsl_name": "fa_light_tex_fa_shadow_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          },
          {
            "slot": 6,
            "stage": "fragment",
            "name": "fa_decal_tex_fa_env_smp",
            "view_name": "fa_decal_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 27,
            "sampler_slot": 10,
            "glsl_name": "fa_decal_tex_fa_env_smp"
          },
          {
            "slot": 7,
            "stage": "fragment",
            "name": "fa_lightmap_fa_env_smp",
            "view_name": "fa_lightmap",
            "sampler_name": "fa_env_smp",
            "view_slot": 26,
            "sampler_slot": 10,
            "glsl_name": "fa_lightmap_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_probe_atlas_fa_env_smp",
            "view_name": "fa_probe_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_probe_atlas_fa_env_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) out vec3 fa_vel_cur;\nlayout(location = 12) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _121 = cross(model[1].xyz, model[2].xyz);\n    float _125 = (dot(model[0].xyz, _121) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_121 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _125, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _125), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _252;\n    if (has_prev)\n    {\n        _252 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _252 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _275 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _282 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_275 * _282).z;\n    fa_pre_r0 = vec3(_275[0].x, _275[1].x, _275[2].x);\n    fa_pre_r1 = vec3(_275[0].y, _275[1].y, _275[2].y);\n    fa_pre_r2 = vec3(_275[0].z, _275[1].z, _275[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _282;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_252)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _282).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nlayout(location = 11) in vec3 fa_vel_cur;\nlayout(location = 12) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _269 = fa_tex_fix(param_2, param_3);\n    vec4 _876 = base_t;\n    _876.x = _269.x;\n    _876.y = _269.y;\n    _876.z = _269.z;\n    base_t = _876;\n    vec4 _285 = (_876 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _831 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _320 = fa_tex_fix(param_6, param_7);\n        vec3 _324 = (_320 * 2.0) - vec3(1.0);\n        vec2 _329 = _324.xy * fa_mesh_fs_params[6].x;\n        vec3 _884 = _324;\n        _884.x = _329.x;\n        _884.y = _329.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _884;\n        _831 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _360 = fa_tex_fix(param_12, param_13);\n    vec4 _887 = mrt;\n    _887.x = _360.x;\n    _887.y = _360.y;\n    _887.z = _360.z;\n    mrt = _887;\n    vec4 _392 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _404 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _436 = fa_tex_fix(param_20, param_21);\n    float _836 = fa_mesh_fs_params[20].x;\n    float _837 = fa_mesh_fs_params[20].y;\n    float _840 = fa_mesh_fs_params[20].z;\n    float _839 = fa_mesh_fs_params[21].w;\n    float _842 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _836 *= _404.y;\n            _837 *= _404.z;\n            _839 *= _392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _840 *= mrt.x;\n            _842 *= mrt.w;\n        }\n    }\n    return Surface(_285.xyz, _285.w, _831, clamp(fa_mesh_fs_params[5].x * _360.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _360.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_404.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _436), _836, _837, fa_mesh_fs_params[21].xyz, _839, _840, fa_mesh_fs_params[20].w, _842, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _726 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _726 = -_726;\n    }\n    vec3 _587 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _602 = normalize(param_2.normal);\n    vec3 _617 = normalize(vec3(dot(fa_pre_r0, _602), dot(fa_pre_r1, _602), dot(fa_pre_r2, _602)));\n    float _629 = _617.z;\n    vec2 e = _617.xy / vec2((abs(_617.x) + abs(_617.y)) + abs(_629));\n    if (_629 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _673 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _680;\n    if (_673)\n    {\n        _680 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _680 = _673;\n    }\n    if (_680)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_68",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_246",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_254",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "prepass_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) out vec3 fa_vel_cur;\nlayout(location = 12) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 13) in vec4 fa_prev_r0;\nlayout(location = 14) in vec4 fa_prev_r1;\nlayout(location = 15) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _225 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_225 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_225 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_225 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _137 = cross(model[1].xyz, model[2].xyz);\n    float _141 = (dot(model[0].xyz, _137) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_137 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _141, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _141), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _353 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _353;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _353 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _353 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _496;\n    if (has_prev)\n    {\n        _496 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _496 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _519 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _526 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_519 * _526).z;\n    fa_pre_r0 = vec3(_519[0].x, _519[1].x, _519[2].x);\n    fa_pre_r1 = vec3(_519[0].y, _519[1].y, _519[2].y);\n    fa_pre_r2 = vec3(_519[0].z, _519[1].z, _519[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _526;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_496)\n    {\n        fa_vtime.x = fa_vel_params[8].y;\n        mat4 param_7 = fa_prev_model();\n        vec3 param_8 = position;\n        vec3 param_9 = normal;\n        vec4 param_10 = tangent;\n        vec2 param_11 = texcoord0;\n        vec4 param_12 = color;\n        VertexData param_13 = fa_vertex_data(param_7, param_8, param_9, param_10, param_11, param_12);\n        vertex(param_13);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _526).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4(param_13.world_pos, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nlayout(location = 11) in vec3 fa_vel_cur;\nlayout(location = 12) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _269 = fa_tex_fix(param_2, param_3);\n    vec4 _876 = base_t;\n    _876.x = _269.x;\n    _876.y = _269.y;\n    _876.z = _269.z;\n    base_t = _876;\n    vec4 _285 = (_876 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _831 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _320 = fa_tex_fix(param_6, param_7);\n        vec3 _324 = (_320 * 2.0) - vec3(1.0);\n        vec2 _329 = _324.xy * fa_mesh_fs_params[6].x;\n        vec3 _884 = _324;\n        _884.x = _329.x;\n        _884.y = _329.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _884;\n        _831 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _360 = fa_tex_fix(param_12, param_13);\n    vec4 _887 = mrt;\n    _887.x = _360.x;\n    _887.y = _360.y;\n    _887.z = _360.z;\n    mrt = _887;\n    vec4 _392 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _392.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _404 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _436 = fa_tex_fix(param_20, param_21);\n    float _836 = fa_mesh_fs_params[20].x;\n    float _837 = fa_mesh_fs_params[20].y;\n    float _840 = fa_mesh_fs_params[20].z;\n    float _839 = fa_mesh_fs_params[21].w;\n    float _842 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _836 *= _404.y;\n            _837 *= _404.z;\n            _839 *= _392.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _840 *= mrt.x;\n            _842 *= mrt.w;\n        }\n    }\n    return Surface(_285.xyz, _285.w, _831, clamp(fa_mesh_fs_params[5].x * _360.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _360.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_404.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _436), _836, _837, fa_mesh_fs_params[21].xyz, _839, _840, fa_mesh_fs_params[20].w, _842, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _726 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _726 = -_726;\n    }\n    vec3 _587 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _726, fa_world_tangent, fa_uv, fa_vertex_color, _587, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _602 = normalize(param_2.normal);\n    vec3 _617 = normalize(vec3(dot(fa_pre_r0, _602), dot(fa_pre_r1, _602), dot(fa_pre_r2, _602)));\n    float _629 = _617.z;\n    vec2 e = _617.xy / vec2((abs(_617.x) + abs(_617.y)) + abs(_629));\n    if (_629 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _673 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _680;\n    if (_673)\n    {\n        _680 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _680 = _673;\n    }\n    if (_680)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 2,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          },
          {
            "slot": 13,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 14,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 15,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r2"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_85",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_234",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          },
          {
            "slot": 2,
            "stage": "vertex",
            "size": 144,
            "struct_name": "fa_vel_params",
            "inst_name": "_491",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 9,
                "offset": 0,
                "glsl_name": "fa_vel_params"
              }
            ]
          },
          {
            "slot": 5,
            "stage": "fragment",
            "size": 16,
            "struct_name": "fa_material",
            "inst_name": "_142",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 1,
                "offset": 0,
                "glsl_name": "fa_material"
              }
            ]
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_254",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 53,
                "offset": 0,
                "glsl_name": "fa_mesh_fs_params"
              }
            ]
          }
        ],
        "views": [
          {
            "texture": {
              "slot": 0,
              "stage": "fragment",
              "name": "fa_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 2,
              "stage": "fragment",
              "name": "fa_normal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 3,
              "stage": "fragment",
              "name": "fa_mr_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 4,
              "stage": "fragment",
              "name": "fa_occlusion_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 5,
              "stage": "fragment",
              "name": "fa_emissive_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "float"
            }
          },
          {
            "texture": {
              "slot": 29,
              "stage": "vertex",
              "name": "fa_prev_pal_tex",
              "multisampled": false,
              "type": "2d",
              "sample_type": "unfilterable_float"
            }
          }
        ],
        "samplers": [
          {
            "slot": 11,
            "stage": "vertex",
            "name": "fa_prev_pal_smp",
            "sampler_type": "nonfiltering"
          },
          {
            "slot": 0,
            "stage": "fragment",
            "name": "fa_smp",
            "sampler_type": "filtering"
          }
        ],
        "texture_sampler_pairs": [
          {
            "slot": 0,
            "stage": "vertex",
            "name": "fa_prev_pal_tex_fa_prev_pal_smp",
            "view_name": "fa_prev_pal_tex",
            "sampler_name": "fa_prev_pal_smp",
            "view_slot": 29,
            "sampler_slot": 11,
            "glsl_name": "fa_prev_pal_tex_fa_prev_pal_smp"
          },
          {
            "slot": 1,
            "stage": "fragment",
            "name": "fa_tex_fa_smp",
            "view_name": "fa_tex",
            "sampler_name": "fa_smp",
            "view_slot": 0,
            "sampler_slot": 0,
            "glsl_name": "fa_tex_fa_smp"
          },
          {
            "slot": 2,
            "stage": "fragment",
            "name": "fa_normal_tex_fa_smp",
            "view_name": "fa_normal_tex",
            "sampler_name": "fa_smp",
            "view_slot": 2,
            "sampler_slot": 0,
            "glsl_name": "fa_normal_tex_fa_smp"
          },
          {
            "slot": 3,
            "stage": "fragment",
            "name": "fa_mr_tex_fa_smp",
            "view_name": "fa_mr_tex",
            "sampler_name": "fa_smp",
            "view_slot": 3,
            "sampler_slot": 0,
            "glsl_name": "fa_mr_tex_fa_smp"
          },
          {
            "slot": 4,
            "stage": "fragment",
            "name": "fa_occlusion_tex_fa_smp",
            "view_name": "fa_occlusion_tex",
            "sampler_name": "fa_smp",
            "view_slot": 4,
            "sampler_slot": 0,
            "glsl_name": "fa_occlusion_tex_fa_smp"
          },
          {
            "slot": 5,
            "stage": "fragment",
            "name": "fa_emissive_tex_fa_smp",
            "view_name": "fa_emissive_tex",
            "sampler_name": "fa_smp",
            "view_slot": 5,
            "sampler_slot": 0,
            "glsl_name": "fa_emissive_tex_fa_smp"
          }
        ]
      }
    },
    "shadow": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _85 = cross(model[1].xyz, model[2].xyz);\n    float _91 = (dot(model[0].xyz, _85) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_85 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _91, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _91), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 6,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 7,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 8,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_144",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          }
        ]
      }
    },
    "shadow_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _187 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_187 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_187 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_187 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _90 = cross(model[1].xyz, model[2].xyz);\n    float _96 = (dot(model[0].xyz, _90) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_90 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _96, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _96), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
      "fs": "#version 430\n\nlayout(location = 0) out vec4 fa_frag_color;\n\nvoid main()\n{\n    fa_frag_color = vec4(gl_FragCoord.z, 0.0, 0.0, 1.0);\n}\n\n",
      "reflection": {
        "vertex_func": {
          "entry_point": "main"
        },
        "fragment_func": {
          "entry_point": "main"
        },
        "attrs": [
          {
            "slot": 0,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_position"
          },
          {
            "slot": 1,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m0"
          },
          {
            "slot": 2,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m1"
          },
          {
            "slot": 3,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m2"
          },
          {
            "slot": 4,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_m3"
          },
          {
            "slot": 5,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_joints"
          },
          {
            "slot": 6,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_weights"
          },
          {
            "slot": 7,
            "type": "vec3",
            "base_type": "Float",
            "glsl_name": "fa_normal"
          },
          {
            "slot": 8,
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_texcoord0"
          },
          {
            "slot": 9,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_tangent"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_color"
          },
          {
            "slot": 11,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d0"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_inst_d1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_149",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 11,
                "offset": 0,
                "glsl_name": "fa_mesh_vs_params"
              }
            ]
          },
          {
            "slot": 3,
            "stage": "vertex",
            "size": 3072,
            "struct_name": "fa_skin",
            "inst_name": "_196",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 192,
                "offset": 0,
                "glsl_name": "fa_skin"
              }
            ]
          }
        ]
      }
    }
  }
}
