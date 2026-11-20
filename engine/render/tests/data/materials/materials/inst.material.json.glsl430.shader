{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "70ec7addbf81ecb38af52c4a5f6d5b8f2213a6d2ef6305cbd78b3ce14189ad63",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3694[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[32];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1535 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1542;\n    if (!_1535)\n    {\n        _1542 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1542 = _1535;\n    }\n    bool _1550;\n    if (!_1542)\n    {\n        _1550 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1550 = _1542;\n    }\n    bool _1557;\n    if (!_1550)\n    {\n        _1557 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1557 = _1550;\n    }\n    bool _1564;\n    if (!_1557)\n    {\n        _1564 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1564 = _1557;\n    }\n    if (_1564)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1574 = vec4(world_pos, 1.0);\n    float _1580 = dot(fa_mesh_fs_params[16], _1574);\n    if (!(_1580 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1602 = vec2(dot(fa_mesh_fs_params[14], _1574), dot(fa_mesh_fs_params[15], _1574)) / vec2(_1580);\n    int _1606 = int(fa_mesh_fs_params[18].x);\n    int _1610 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1610) + clamp(int(floor(((_1602.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1610 - 1)) * _1606)) + clamp(int(floor(((_1602.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1606 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1686 = fa_cluster_texel(param);\n    return ivec2(int(_1686.x), int(_1686.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5127 = fa_cluster_lookup(param);\n    fa_cl_slot = _5127.x;\n    fa_cl_local = _5127.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6285 = fa_linear_to_srgb(param);\n        c = _6285;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6293 = fa_srgb_to_linear(param_1);\n            c = _6293;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _480;\n    if (i.front_facing)\n    {\n        _480 = i.world_normal;\n    }\n    else\n    {\n        _480 = -i.world_normal;\n    }\n    vec3 _504 = normalize(i.world_tangent.xyz - (_480 * dot(_480, i.world_tangent.xyz)));\n    vec3 _531 = normalize(((_504 * m.x) + ((cross(_480, _504) * i.world_tangent.w) * m.y)) + (_480 * m.z));\n    vec3 _534;\n    if (i.front_facing)\n    {\n        _534 = _531;\n    }\n    else\n    {\n        _534 = -_531;\n    }\n    return _534;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6324 = fa_tex_fix(param_2, param_3);\n    vec4 _7890 = base_t;\n    _7890.x = _6324.x;\n    _7890.y = _6324.y;\n    _7890.z = _6324.z;\n    base_t = _7890;\n    vec4 _6338 = (_7890 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7699 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6370 = fa_tex_fix(param_6, param_7);\n        vec3 _6373 = (_6370 * 2.0) - vec3(1.0);\n        vec2 _6378 = _6373.xy * fa_mesh_fs_params[6].x;\n        vec3 _7898 = _6373;\n        _7898.x = _6378.x;\n        _7898.y = _6378.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7898;\n        _7699 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6406 = fa_tex_fix(param_12, param_13);\n    vec4 _7901 = mrt;\n    _7901.x = _6406.x;\n    _7901.y = _6406.y;\n    _7901.z = _6406.z;\n    mrt = _7901;\n    vec4 _6434 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6434.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6445 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6475 = fa_tex_fix(param_20, param_21);\n    float _7704 = fa_mesh_fs_params[20].x;\n    float _7705 = fa_mesh_fs_params[20].y;\n    float _7708 = fa_mesh_fs_params[20].z;\n    float _7707 = fa_mesh_fs_params[21].w;\n    float _7710 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7704 *= _6445.y;\n            _7705 *= _6445.z;\n            _7707 *= _6434.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7708 *= mrt.x;\n            _7710 *= mrt.w;\n        }\n    }\n    return Surface(_6338.xyz, _6338.w, _7699, clamp(fa_mesh_fs_params[5].x * _6406.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6406.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6445.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6475), _7704, _7705, fa_mesh_fs_params[21].xyz, _7707, _7708, fa_mesh_fs_params[20].w, _7710, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1766 = rect.zw - rect.xy;\n    vec2 _1770 = _1766 * atlas;\n    vec2 _1774 = ddx * _1770;\n    vec2 _1778 = ddy * _1770;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1766), clamp(0.5 * log2(max(max(dot(_1774, _1774), dot(_1778, _1778)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1811 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1818;\n    if (!_1811)\n    {\n        _1818 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1818 = _1811;\n    }\n    if (_1818)\n    {\n        return;\n    }\n    vec3 _1824 = dFdx(world_pos);\n    vec3 _1827 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1831 = fa_cluster_texel(param);\n    int _1835 = int(_1831.w);\n    if (_1835 < 1)\n    {\n        return;\n    }\n    int _1845 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1845;\n    vec4 _1849 = fa_light_texel(param_1);\n    vec2 _1852 = _1849.yz;\n    int _1856 = int(_1849.w);\n    int param_2 = _1845 + 1;\n    vec4 _1861 = fa_light_texel(param_2);\n    float _1862 = _1861.x;\n    int _1868 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1872 = int(_1831.z);\n    vec3 _2137;\n    for (int k = 0; k < _1835; k++)\n    {\n        int _1885 = _1872 + k;\n        int param_3 = _1856 + (_1885 >> 2);\n        int _1902 = (_1845 + 2) + (int(fa_light_texel(param_3)[_1885 & 3]) * 7);\n        int param_4 = _1902 + 6;\n        vec4 _1907 = fa_light_texel(param_4);\n        if (((int(_1907.w + 0.5) >> _1868) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1902;\n        vec4 _1922 = fa_light_texel(param_5);\n        int param_6 = _1902 + 1;\n        vec4 _1927 = fa_light_texel(param_6);\n        int param_7 = _1902 + 2;\n        vec4 _1932 = fa_light_texel(param_7);\n        vec3 _1935 = _1922.xyz;\n        float _1940 = dot(_1935, world_pos) + _1922.w;\n        vec3 _1942 = _1927.xyz;\n        float _1947 = dot(_1942, world_pos) + _1927.w;\n        vec3 _1949 = _1932.xyz;\n        float _1954 = dot(_1949, world_pos) + _1932.w;\n        bool _1959 = abs(_1940) > 0.5;\n        bool _1967;\n        if (!_1959)\n        {\n            _1967 = abs(_1947) > 0.5;\n        }\n        else\n        {\n            _1967 = _1959;\n        }\n        bool _1975;\n        if (!_1967)\n        {\n            _1975 = abs(_1954) > 0.5;\n        }\n        else\n        {\n            _1975 = _1967;\n        }\n        if (_1975)\n        {\n            continue;\n        }\n        float _1990 = clamp(dot(geo_normal, normalize(_1949)) * _1907.z, 0.0, 1.0);\n        if (_1990 <= 0.0)\n        {\n            continue;\n        }\n        float _2010 = (clamp((0.5 - abs(_1954)) * 10.0, 0.0, 1.0) * _1990) * _1907.x;\n        vec2 _2018 = vec2(_1940 + 0.5, 0.5 - _1947);\n        vec2 _2028 = vec2(dot(_1935, _1824), dot(_1942, _1824));\n        vec2 _2038 = vec2(dot(_1935, _1827), dot(_1942, _1827));\n        int param_8 = _1902 + 5;\n        vec4 _2043 = fa_light_texel(param_8);\n        int param_9 = _1902 + 3;\n        vec4 _2048 = fa_light_texel(param_9);\n        int param_10 = _1902 + 4;\n        vec4 _2053 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2043.xyz;\n        bool _2063 = _2048.z > _2048.x;\n        if (_2063)\n        {\n            vec4 param_11 = _2048;\n            vec2 param_12 = _2018;\n            vec2 param_13 = _1852;\n            vec2 param_14 = _2028;\n            vec2 param_15 = _2038;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1862 > 0.5) && (_1862 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2089 = fa_dc_to_linear(param_16);\n                vec4 _7787 = tx;\n                _7787.x = _2089.x;\n                _7787.y = _2089.y;\n                _7787.z = _2089.z;\n                tx = _7787;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2010 * tex_a) * _2043.w, 0.0, 1.0)));\n        if (_2053.z > _2053.x)\n        {\n            vec4 param_17 = _2053;\n            vec2 param_18 = _2018;\n            vec2 param_19 = _1852;\n            vec2 param_20 = _2028;\n            vec2 param_21 = _2038;\n            vec4 _2133 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1862 > 1.5)\n            {\n                vec3 param_22 = _2133.xyz;\n                vec3 _2143 = fa_dc_to_srgb(param_22);\n                _2137 = _2143;\n            }\n            else\n            {\n                _2137 = _2133.xyz;\n            }\n            vec3 _2152 = (_2137 * 2.0) - vec3(1.0);\n            vec2 _2157 = _2152.xy * _1907.y;\n            vec3 _2179 = (normalize(_1935) * _2157.x) + (normalize(_1942) * _2157.y);\n            vec3 _2182 = normalize(normal);\n            normal = normalize(mix(_2182, normalize((_2182 * max(_2152.z, 0.0500000007450580596923828125)) + (_2179 - (_2182 * dot(_2182, _2179)))), vec3(clamp(_2010 * (_2063 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3620 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3627 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3630 = int(_3620);\n    int _3633 = int(_3627);\n    float _3643 = _3627 - float(_3633);\n    int _3698 = (_3630 * 9) + _3633;\n    int _3718 = ((_3630 + 1) * 9) + _3633;\n    return mix(mix(_3694[_3698], _3694[_3698 + 1], _3643), mix(_3694[_3718], _3694[_3718 + 1], _3643), _3620 - float(_3630));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7622 = false;\n    float _7623 = 1.0;\n    float _7624 = 1.0;\n    float _7625 = 1.0;\n    float _7626 = 0.0;\n    float _7627 = 0.0;\n    float _7628 = 0.0;\n    float _7629 = 0.0;\n    float _7631 = 1.0;\n    bool _7632 = false;\n    vec3 _7633 = vec3(0.0);\n    float _7634 = 1.0;\n    float _7635 = 1.0;\n    float _7636 = 1.0;\n    float _7637 = 0.0;\n    float _7638 = 0.0;\n    vec3 _7639 = vec3(1.0, 0.0, 0.0);\n    vec3 _7640 = vec3(0.0, 0.0, 1.0);\n    float _7641 = 1.0;\n    float _7642 = 1.0;\n    float _3769 = clamp(s.specular, 0.0, 1.0);\n    float _3773 = clamp(s.ior, 1.0, 3.0);\n    bool _3778 = (_3769 != 1.0) || (_3773 != 1.5);\n    bool _3787;\n    if (!_3778)\n    {\n        _3787 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3787 = _3778;\n    }\n    if (_3787)\n    {\n        float _3795 = (_3773 - 1.0) / (_3773 + 1.0);\n        f0 = mix(min(vec3(_3795 * _3795) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3769, s.albedo, vec3(metallic));\n        _7623 = mix(_3769, 1.0, metallic);\n        _7622 = true;\n    }\n    float _3822 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3822 > 0.0)\n    {\n        float _3830 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7626 = _3822;\n        _7627 = _3830;\n        float _3837 = _3830 * _3830;\n        _7628 = _3837;\n        _7629 = _3837 * _3837;\n        float _3849 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7631 = _3849;\n        _7624 = 1.0 - (_3822 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3849, 0.0, 1.0), 5.0))));\n        _7622 = true;\n    }\n    vec3 _3868 = max(s.sheen_color, vec3(0.0));\n    float _3877 = max(_3868.x, max(_3868.y, _3868.z));\n    if (_3877 > 0.0)\n    {\n        float _3885 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7632 = true;\n        _7633 = _3868;\n        _7634 = _3885;\n        _7635 = _3885 * _3885;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3885;\n        float _3902 = fa_sheen_albedo(param, param_1);\n        _7637 = _3902;\n        _7636 = 1.0 - min(_3877 * _3902, 1.0);\n        _7622 = true;\n    }\n    _7625 = _7624 * _7636;\n    float _3921 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3921 != 0.0)\n    {\n        vec3 _3936 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3936;\n        if (dot(_3936, _3936) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3948 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3948.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3948.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3948.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3952 = t;\n        vec3 _3953 = normalize(_3952);\n        t = _3953;\n        vec3 _3978 = normalize((_3953 * cos(s.anisotropy_rotation)) + ((cross(n, _3953) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7639 = _3978;\n        _7640 = cross(n, _3978);\n        float _3988 = roughness * roughness;\n        float _3994 = mix(_3988, 1.0, _3921 * _3921);\n        bool _3996 = _3921 > 0.0;\n        _7641 = _3996 ? _3994 : _3988;\n        _7642 = _3996 ? _3988 : _3994;\n        _7638 = _3921;\n        _7622 = true;\n    }\n    return FaLayers(_7622, _7623, _7624, _7625, _7626, _7627, _7628, _7629, i.world_normal, _7631, _7632, _7633, _7634, _7635, _7636, _7637, _7638, _7639, _7640, _7641, _7642);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3377 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3377;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _784 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _797 = (c - (ru * hx)) - p;\n        vec3 _803 = ru * (2.0 * hx);\n        float _809 = max(dot(_803, _803), 9.9999999392252902907785028219223e-09);\n        float _813 = dot(_797, _803);\n        float t = clamp((-_813) / _809, 0.0, 1.0);\n        if (_784)\n        {\n            float _828 = dot(r, _803);\n            float _834 = _809 - (_828 * _828);\n            if (abs(_834) > (9.9999997473787516355514526367188e-06 * _809))\n            {\n                t = clamp(((dot(r, _797) * _828) - _813) / _834, 0.0, 1.0);\n            }\n        }\n        return (p + _797) + (_803 * t);\n    }\n    vec3 q = p;\n    float _866 = dot(r, axis);\n    bool _874;\n    if (_784)\n    {\n        _874 = abs(_866) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _874 = _784;\n    }\n    if (_874)\n    {\n        float _884 = dot(c - p, axis) / _866;\n        if (_884 > 0.0)\n        {\n            q = p + (r * _884);\n        }\n    }\n    vec3 _897 = q - c;\n    vec2 xy = vec2(dot(_897, ru), dot(_897, uu));\n    if (shape > 0.5)\n    {\n        float _912 = length(xy);\n        if (_912 > hx)\n        {\n            xy *= (hx / _912);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _546 = abs(d);\n    float _548 = _546.x;\n    float _550 = _546.y;\n    bool _551 = _548 >= _550;\n    bool _559;\n    if (_551)\n    {\n        _559 = _548 >= _546.z;\n    }\n    else\n    {\n        _559 = _551;\n    }\n    int _560;\n    if (_559)\n    {\n        _560 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _575;\n        if (_550 >= _546.z)\n        {\n            _575 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _575 = (d.z > 0.0) ? 4 : 5;\n        }\n        _560 = _575;\n    }\n    return _560;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _704 = dot(d, right);\n    float _708 = dot(d, up);\n    float _719;\n    if (((_704 * _704) + (_708 * _708)) > 1.0000000133514319600180897396058e-10)\n    {\n        _719 = atan(_708, _704) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _719 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_719 - floor(_719)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _950 = fa_light_base(param);\n    bool _954 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _950;\n    vec4 _958 = fa_light_texel(param_1);\n    int param_2 = _950 + 1;\n    vec4 _963 = fa_light_texel(param_2);\n    float _966 = _963.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _978 = _954 && (_966 > 2.5);\n    fa_light_is_area = _978;\n    bool _980 = _966 < 0.5;\n    vec3 l;\n    if (_980)\n    {\n        l = normalize(_958.xyz);\n        if (_954)\n        {\n            int param_3 = _950 + 6;\n            vec4 _994 = fa_light_texel(param_3);\n            if (_994.z > 0.5)\n            {\n                int param_4 = _950 + 4;\n                vec4 _1004 = fa_light_texel(param_4);\n                int param_5 = _950 + 5;\n                vec4 _1009 = fa_light_texel(param_5);\n                vec2 param_6 = _994.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1004.xyz) * _1004.w, (-dot(world_pos, _1009.xyz)) * _1009.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1039 = _958.xyz;\n        vec3 _1041 = _1039 - world_pos;\n        vec3 to_light = _1041;\n        float _1044 = length(_1041);\n        float reach = _1044;\n        bool front = true;\n        if (_978)\n        {\n            int param_8 = _950 + 7;\n            reach = max(_1044 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _950 + 4;\n            vec4 _1068 = fa_light_texel(param_9);\n            int param_10 = _950 + 5;\n            vec4 _1073 = fa_light_texel(param_10);\n            int param_11 = _950 + 6;\n            vec4 _1078 = fa_light_texel(param_11);\n            float _1079 = _1078.w;\n            int param_12 = _950 + 2;\n            vec3 _1086 = normalize(fa_light_texel(param_12).xyz);\n            bool _1088 = _1079 > 1.5;\n            bool _1096;\n            if (!_1088)\n            {\n                _1096 = dot(_1086, to_light) < 0.0;\n            }\n            else\n            {\n                _1096 = _1088;\n            }\n            front = _1096;\n            vec3 r = vec3(0.0);\n            vec3 _1105 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1109 = dot(n, n) > 0.5;\n            bool _1117;\n            if (_1109)\n            {\n                _1117 = dot(_1105, _1105) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1117 = _1109;\n            }\n            if (_1117)\n            {\n                r = reflect(-normalize(_1105), normalize(n));\n            }\n            vec3 param_13 = _1039;\n            vec3 param_14 = _1086;\n            vec3 param_15 = _1068.xyz;\n            vec3 param_16 = _1073.xyz;\n            float param_17 = _1068.w;\n            float param_18 = _1073.w;\n            float param_19 = _1079;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1153 = length(to_light);\n        dist = _1153;\n        l = to_light / vec3(max(_1153, 9.9999997473787516355514526367188e-05));\n        float _1167 = reach / max(_958.w, 0.001000000047497451305389404296875);\n        float _1173 = clamp(1.0 - (_1167 * _1167), 0.0, 1.0);\n        float _1175;\n        if (front)\n        {\n            _1175 = _1173 * _1173;\n        }\n        else\n        {\n            _1175 = 0.0;\n        }\n        atten = _1175;\n        bool _1186 = _966 < 2.5;\n        if ((_966 > 1.5) && _1186)\n        {\n            int param_22 = _950 + 2;\n            vec4 _1194 = fa_light_texel(param_22);\n            float _1204 = _1194.w;\n            int param_23 = _950 + 3;\n            vec4 _1209 = fa_light_texel(param_23);\n            float _1210 = _1209.x;\n            float cos_inner = _1210;\n            if (_1210 > 1.5)\n            {\n                cos_inner = mix(_1204, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1204, cos_inner, dot(-l, normalize(_1194.xyz)));\n        }\n        if (_954 && (_966 < 1.5))\n        {\n            int param_24 = _950 + 6;\n            vec4 _1234 = fa_light_texel(param_24);\n            if (_1234.z > 0.5)\n            {\n                vec3 _1242 = -to_light;\n                int param_25 = _950 + 4;\n                int param_26 = _950 + 5;\n                vec3 _1256 = fa_light_texel(param_25).xyz;\n                vec3 _1260 = fa_light_texel(param_26).xyz;\n                vec3 _1269 = vec3(dot(_1242, _1256), dot(_1242, _1260), dot(_1242, cross(_1256, _1260)));\n                vec3 param_27 = _1269;\n                int _1273 = fa_cube_face(param_27);\n                int param_28 = _1273;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1300 = vec2(dot(_1269, cross(param_29, param_30)), dot(_1269, param_30)) / vec2(max(dot(_1269, param_29), 9.9999997473787516355514526367188e-05));\n                int _1304 = _1273 / 3;\n                vec2 param_31 = _1234.xy + (vec2(float(_1273 - (_1304 * 3)), float(_1304)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1300.x), 0.5 - (0.5 * _1300.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _950 + 7;\n            vec4 _1334 = fa_light_texel(param_33);\n            if (_1334.z > 0.5)\n            {\n                int param_34 = _950 + 2;\n                int param_35 = _950 + 4;\n                int param_36 = _950 + 5;\n                vec2 param_37 = _1334.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_954 && _1186)\n            {\n                int param_42 = _950 + 6;\n                vec4 _1381 = fa_light_texel(param_42);\n                int param_43 = _950 + 7;\n                vec4 _1386 = fa_light_texel(param_43);\n                bool _1389 = _1381.z > 0.5;\n                bool _1396;\n                if (!_1389)\n                {\n                    _1396 = _1386.z > 0.5;\n                }\n                else\n                {\n                    _1396 = _1389;\n                }\n                if (_1396)\n                {\n                    int param_44 = _950 + 2;\n                    vec4 _1403 = fa_light_texel(param_44);\n                    vec3 _1407 = normalize(_1403.xyz);\n                    int param_45 = _950 + 4;\n                    vec4 _1412 = fa_light_texel(param_45);\n                    int param_46 = _950 + 5;\n                    vec4 _1417 = fa_light_texel(param_46);\n                    if (_1389)\n                    {\n                        vec3 _1425 = -to_light;\n                        float _1432 = _1403.w;\n                        float _1448 = 0.5 / max(dot(_1425, _1407) * (sqrt(max(1.0 - (_1432 * _1432), 0.0)) / max(_1432, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1381.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1425, _1412.xyz) * _1448), 0.5 - (dot(_1425, _1417.xyz) * _1448));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1386.z > 0.5)\n                    {\n                        vec2 param_49 = _1386.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1407;\n                        vec3 param_52 = _1412.xyz;\n                        vec3 param_53 = _1417.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7610 = _963.xyz * atten;\n    if (_954)\n    {\n        _7610 *= fa_light_tint;\n    }\n    int _1517;\n    if (_980)\n    {\n        _1517 = 0;\n    }\n    else\n    {\n        _1517 = ((_966 > 1.5) && (_966 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7610, atten, 1.0, dist, _1517);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2254;\n    if (i == 0)\n    {\n        _2254 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2270;\n        if (i == 1)\n        {\n            _2270 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2278;\n            if (i == 2)\n            {\n                _2278 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2278 = fa_shadows[24].w;\n            }\n            _2270 = _2278;\n        }\n        _2254 = _2270;\n    }\n    return _2254;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2311 = fa_shadow_depth(param, param_1);\n    float _2315;\n    if (conv.x < 0.5)\n    {\n        _2315 = _2311;\n    }\n    else\n    {\n        _2315 = (conv.y * conv.z) / (conv.z - (_2311 * (conv.z - conv.y)));\n    }\n    return _2315;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2242 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2242), sin(_2242)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2361 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2370;\n        if (k < 0.0)\n        {\n            _2370 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2370 = k;\n        }\n        float _2390 = clamp((_2370 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2361;\n            vec2 _2409 = fa_shadow_vogel(param_3, param_4, param_5) * _2390;\n            vec2 param_6 = uv + (_2409 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2421 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2421 < (zr - (length(_2409) * plane)))\n            {\n                sum += _2421;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2447 = sum / cnt;\n        float _2457;\n        if (k < 0.0)\n        {\n            _2457 = (-k) / max(_2447, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2457 = k;\n        }\n        radius = clamp(((max(zr - _2447, 0.0) * unit) * _2457) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2479 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2479; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2479;\n        float param_11 = _2361;\n        vec2 _2498 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2498 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2498) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2479);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2540 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2545 = clamp(dot(n, l), 0.0, 1.0);\n    float _2551 = sqrt(1.0 - (_2545 * _2545));\n    float _2558 = min(_2551 / max(_2545, 0.20000000298023223876953125), 4.0);\n    float _2563;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2563 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2563 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2588 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2563 * _2551)), 1.0);\n    float _2595 = _2588.x;\n    bool _2598 = _2595 < fa_shadows[ci * 1 + 16].x;\n    bool _2607;\n    if (!_2598)\n    {\n        _2607 = _2595 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2607 = _2598;\n    }\n    bool _2616;\n    if (!_2607)\n    {\n        _2616 = _2588.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2616 = _2607;\n    }\n    bool _2625;\n    if (!_2616)\n    {\n        _2625 = _2588.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2625 = _2616;\n    }\n    bool _2632;\n    if (!_2625)\n    {\n        _2632 = _2588.z > 1.0;\n    }\n    else\n    {\n        _2632 = _2625;\n    }\n    if (_2632)\n    {\n        return -1.0;\n    }\n    float _2640;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2640 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2640 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2588.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2588.z - ((_2640 * (1.0 + (0.5 * _2558))) / _2540);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2540;\n    float param_5 = _2540 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2558, 3.0)) * 0.5) / _2540;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3018 = int(fa_shadows[25].x + 0.5);\n    if (_3018 < 1)\n    {\n        return 1.0;\n    }\n    float _3033 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3018 - 1;\n    if (_3033 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3045 = _3018 > 1;\n    bool _3052;\n    if (_3045)\n    {\n        _3052 = _3033 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3052 = _3045;\n    }\n    if (_3052)\n    {\n        ci = 1;\n    }\n    bool _3056 = _3018 > 2;\n    bool _3063;\n    if (_3056)\n    {\n        _3063 = _3033 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3063 = _3056;\n    }\n    if (_3063)\n    {\n        ci = 2;\n    }\n    bool _3067 = _3018 > 3;\n    bool _3074;\n    if (_3067)\n    {\n        _3074 = _3033 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3074 = _3067;\n    }\n    if (_3074)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3018)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3100 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3100;\n        if (_3100 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3125;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3125 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3125 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3144 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3125, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3155 = clamp((_3033 - (fa_shadow_split_at(param_7) - _3144)) / _3144, 0.0, 1.0);\n        if (_3155 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3018)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3176 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3176;\n                if (_3176 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3155);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2698 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2705;\n    if (!_2698)\n    {\n        _2705 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2705 = _2698;\n    }\n    if (_2705)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2718 = fa_light_texel(param);\n    float _2719 = _2718.x;\n    if (_2719 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2728 = int(_2719 + 0.5);\n    int param_1 = _2728;\n    vec4 _2732 = fa_light_texel(param_1);\n    int param_2 = _2728 + 1;\n    vec4 _2737 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2740 = _2732.y;\n    if (_2740 > 0.0)\n    {\n        float _2757 = 1.0 - smoothstep(0.75 * _2740, _2740, length(world - fa_shadows[27].xyz));\n        fade = _2757;\n        if (_2757 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2732.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2781 = (_2728 + 2) + (face * 6);\n    int param_4 = _2781;\n    int param_5 = _2781 + 1;\n    int param_6 = _2781 + 3;\n    vec4 _2795 = fa_light_texel(param_6);\n    int param_7 = _2781 + 4;\n    vec4 _2800 = fa_light_texel(param_7);\n    int param_8 = _2781 + 5;\n    vec4 _2805 = fa_light_texel(param_8);\n    float _2817 = _2805.x * max(dot(_2795, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2822 = clamp(dot(n, l), 0.0, 1.0);\n    float _2845 = clamp(dot(n, _2795.xyz), -1.0, 1.0);\n    float _2864 = min(sqrt(1.0 - (_2845 * _2845)) / max(abs(dot(n, world - lpos)) / max(dot(_2795, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2867 = _2737.y;\n    float _2869;\n    if (_2867 > 0.0)\n    {\n        _2869 = _2867;\n    }\n    else\n    {\n        _2869 = 1.5 * _2817;\n    }\n    vec4 _2889 = vec4(world + (n * (_2869 * sqrt(1.0 - (_2822 * _2822)))), 1.0);\n    float _2893 = dot(_2795, _2889);\n    float _2896 = _2805.y;\n    if (_2893 < _2896)\n    {\n        return 1.0;\n    }\n    vec2 _2911 = vec2(dot(fa_light_texel(param_4), _2889), dot(fa_light_texel(param_5), _2889)) / vec2(_2893);\n    float _2913 = _2911.x;\n    bool _2916 = _2913 < _2800.x;\n    bool _2925;\n    if (!_2916)\n    {\n        _2925 = _2913 > _2800.z;\n    }\n    else\n    {\n        _2925 = _2916;\n    }\n    bool _2934;\n    if (!_2925)\n    {\n        _2934 = _2911.y < _2800.y;\n    }\n    else\n    {\n        _2934 = _2925;\n    }\n    bool _2943;\n    if (!_2934)\n    {\n        _2943 = _2911.y > _2800.w;\n    }\n    else\n    {\n        _2943 = _2934;\n    }\n    if (_2943)\n    {\n        return 1.0;\n    }\n    float _2949 = _2737.x;\n    float _2951;\n    if (_2949 > 0.0)\n    {\n        _2951 = _2949;\n    }\n    else\n    {\n        _2951 = 1.5 * _2817;\n    }\n    vec2 param_9 = _2911;\n    vec4 param_10 = _2800;\n    float param_11 = _2893 - (_2951 * (1.0 + (0.5 * _2864)));\n    float param_12 = _2817;\n    float param_13 = 1.0;\n    float param_14 = _2805.z * 0.25;\n    float param_15 = (_2817 * min(_2864, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2896, _2805.z);\n    int param_17 = int(_2732.z + 0.5);\n    float param_18 = _2732.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4506 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4513;\n    if (!_4506)\n    {\n        _4513 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4513 = _4506;\n    }\n    if (_4513)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4526 = fa_light_texel(param);\n    float _4527 = _4526.y;\n    float len = _4527;\n    if (_4527 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4539 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4549 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4539);\n    if (_4549 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4555 = len;\n    float _4558 = min(_4555, 0.89999997615814208984375 * dist);\n    len = _4558;\n    float _4563 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4539);\n    float _4568 = _4563 + (0.5 * _4558);\n    vec3 _4574 = world + (gn * _4563);\n    float _4576 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4640;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4591 = (float(k) + _4576) * 0.083333335816860198974609375;\n        vec3 _4599 = _4574 + (l * (_4591 * len));\n        vec4 _4605 = vec4(_4599, 1.0);\n        float _4611 = dot(fa_mesh_fs_params[28], _4605);\n        if (_4611 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4631 = vec2(dot(fa_mesh_fs_params[26], _4605), dot(fa_mesh_fs_params[27], _4605)) / vec2(_4611);\n        float _4635 = _4631.x * 0.5;\n        float _4636 = _4635 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4640 = (_4631.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4640 = 0.5 - (_4631.y * 0.5);\n        }\n        bool _4656 = _4636 < 0.0;\n        bool _4663;\n        if (!_4656)\n        {\n            _4663 = _4636 >= 1.0;\n        }\n        else\n        {\n            _4663 = _4656;\n        }\n        bool _4670;\n        if (!_4663)\n        {\n            _4670 = _4640 < 0.0;\n        }\n        else\n        {\n            _4670 = _4663;\n        }\n        bool _4677;\n        if (!_4670)\n        {\n            _4677 = _4640 >= 1.0;\n        }\n        else\n        {\n            _4677 = _4670;\n        }\n        if (_4677)\n        {\n            break;\n        }\n        vec4 _4696 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4636, _4640) * fa_mesh_fs_params[24].zw), 0);\n        if (_4696.w < 0.5)\n        {\n            continue;\n        }\n        float _4715 = (dot(fa_mesh_fs_params[29].xyz, _4599) + fa_mesh_fs_params[29].w) - _4696.x;\n        if ((_4715 > _4563) && (_4715 < _4568))\n        {\n            occ = max(occ, (1.0 - (_4591 * _4591)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4636, 0.5 - _4635), min(_4640, 1.0 - _4640))));\n        }\n    }\n    return 1.0 - (occ * _4549);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _5154 = fa_lm.z > 0.5;\n    bool _5160;\n    if (_5154)\n    {\n        int param = li;\n        _5160 = fa_light_baked(param);\n    }\n    else\n    {\n        _5160 = _5154;\n    }\n    if (_5160)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5184 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7679 = _5184.color;\n    float _7681 = _5184.shadow;\n    bool _5187 = _5184.type == 0;\n    if (_5187 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5184.direction;\n        float _5198 = fa_shadow_factor(param_5, param_6);\n        _7681 = _5198;\n        _7679 *= _5198;\n    }\n    else\n    {\n        bool _5209 = _5184.type != 0;\n        bool _5215;\n        if (_5209)\n        {\n            _5215 = _5184.attenuation > 0.0;\n        }\n        else\n        {\n            _5215 = _5209;\n        }\n        if (_5215)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5184.direction;\n            float _5234 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7681 = _5234;\n            _7679 *= _5234;\n        }\n    }\n    bool _5244 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5250;\n    if (_5244)\n    {\n        _5250 = _5184.attenuation > 0.0;\n    }\n    else\n    {\n        _5250 = _5244;\n    }\n    if (_5250)\n    {\n        float _5257;\n        if (_5187)\n        {\n            _5257 = 1000000000.0;\n        }\n        else\n        {\n            _5257 = _5184._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5184.direction;\n        float param_18 = _5257;\n        float _5275 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7681 *= _5275;\n        _7679 *= _5275;\n    }\n    return LightSample(_5184.direction, _7679, _5184.attenuation, _7681, _5184._distance, _5184.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5318 = v - (n * dot(v, n));\n    vec3 t = _5318;\n    float _5322 = dot(_5318, _5318);\n    float l2 = _5322;\n    if (_5322 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5332;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5332 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5332 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5332;\n        l2 = dot(_5332, _5332);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5367 = dot(a, a);\n    float _5371 = dot(b, b);\n    if ((_5367 < 1.0000000195414813782625560981111e-24) || (_5371 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5385 = a * inversesqrt(_5367);\n    vec3 _5390 = b * inversesqrt(_5371);\n    float _5394 = dot(_5385, _5390);\n    float _5397 = abs(_5394);\n    float g = (((((((((((0.0416471660137176513671875 * _5397) - 0.1924748718738555908203125) * _5397) + 0.4179156124591827392578125) * _5397) - 0.616057217121124267578125) * _5397) + 0.777722418308258056640625) * _5397) - 0.999542415142059326171875) * _5397) + 1.570791721343994140625;\n    if (_5394 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5394 * _5394), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5385, _5390) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5454 = a.z > 0.0;\n    bool _5458 = b.z > 0.0;\n    if (_5454 && _5458)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5454 != _5458)\n        {\n            vec3 _5493 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5493.z = 0.0;\n            if (_5454)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5493;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5493;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5493;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5493;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5542 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5568 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5594 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5620 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5542;\n    vec3 param_1 = _5568;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5568;\n    vec3 param_7 = _5594;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5594;\n    vec3 param_13 = _5620;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5620;\n    vec3 param_19 = _5542;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5769 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5793 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5809 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5769;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5793;\n    vec4 param_9 = m;\n    vec3 param_10 = _5769;\n    vec3 param_11 = _5793;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5809;\n    vec4 param_14 = m;\n    vec3 param_15 = _5769;\n    vec3 param_16 = _5809;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5867 = fa_light_base(param);\n    int param_1 = _5867;\n    int param_2 = _5867 + 1;\n    int param_3 = _5867 + 2;\n    int param_4 = _5867 + 4;\n    vec4 _5889 = fa_light_texel(param_4);\n    int param_5 = _5867 + 5;\n    vec4 _5894 = fa_light_texel(param_5);\n    int param_6 = _5867 + 6;\n    vec4 _5899 = fa_light_texel(param_6);\n    float _5900 = _5899.w;\n    vec3 _5905 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5907 = _5900 < 1.5;\n    bool _5914;\n    if (_5907)\n    {\n        _5914 = dot(normalize(fa_light_texel(param_3).xyz), _5905) >= 0.0;\n    }\n    else\n    {\n        _5914 = _5907;\n    }\n    if (_5914)\n    {\n        return vec3(0.0);\n    }\n    bool _5923 = (_5900 > 0.5) && _5907;\n    float _5927 = _5923 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5930 = _5889.xyz;\n    float _5932 = _5889.w;\n    vec3 _5938 = _5894.xyz;\n    float _5940 = _5894.w;\n    vec3 up = _5938 * (_5940 * _5927);\n    float _5946;\n    if (_5923)\n    {\n        _5946 = (3.1415927410125732421875 * _5932) * _5932;\n    }\n    else\n    {\n        _5946 = (4.0 * _5932) * _5940;\n    }\n    if (_5900 > 1.5)\n    {\n        vec3 _5972 = cross(_5930, -_5905);\n        vec3 perp = _5972;\n        float _5976 = dot(_5972, _5972);\n        vec3 _5979;\n        if (_5976 > 1.0000000133514319600180897396058e-10)\n        {\n            _5979 = perp * inversesqrt(_5976);\n        }\n        else\n        {\n            _5979 = _5938;\n        }\n        perp = _5979;\n        up = _5979 * _5940;\n    }\n    float _6000 = max(_5946, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6010 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6010;\n    vec3 param_10 = n;\n    vec3 param_11 = _5905;\n    vec3 _6018 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6010;\n    vec3 param_13 = n;\n    vec3 param_14 = _5930 * (_5932 * _5927);\n    vec3 _6026 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6010;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6034 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5900;\n    vec3 param_20 = _6018;\n    vec3 param_21 = _6026;\n    vec3 param_22 = _6034;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6053 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6053;\n    vec2 param_26 = _6053 + vec2(64.0, 0.0);\n    vec4 _6063 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5900;\n    vec3 param_29 = _6018;\n    vec3 param_30 = _6026;\n    vec3 param_31 = _6034;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6063.x) + ((vec3(f90) - f0) * _6063.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5905, _5905)) + _6000) / _6000) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4243 = 1.0 / alpha;\n    return ((2.0 + _4243) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4243)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4278 = max(dot(L.nc, l), 0.0);\n    float _4284 = max(dot(L.nc, h), 0.0);\n    float _4293 = ((_4284 * _4284) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4293) * _4293)) * (0.5 / max(mix((2.0 * _4278) * L.coat_ndv, _4278 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4278)) * _4278;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6131;\n    if (L.sheen_on)\n    {\n        _6131 = L.sheen_scale;\n    }\n    else\n    {\n        _6131 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6131);\n    vec3 _6144 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6155 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6164 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6144), 0.0);\n        float param_13 = _6164;\n        float param_14 = ndv;\n        result += ((L.sheen * _6155) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6164)) * _6164) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6144;\n        float param_18 = max(dot(v, _6144), 0.0);\n        result += (_6155 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4146 = tdh / at;\n    float _4150 = bdh / ab;\n    float _4162 = ((_4146 * _4146) + (_4150 * _4150)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4162) * _4162);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4342 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4421 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4421) * _4421);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4342);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4342));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3552 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3555 = _3552.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3555 * _3555, exp2((-9.27999973297119140625) * ndv)) * _3555) + _3552.y)) + _3552.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3406 = rough * rough;\n    float _3436 = 0.60000002384185791015625 * _3406;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3406)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3436, 0.0500000007450580596923828125 + _3436, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3406 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4029;\n        if (L.aniso >= 0.0)\n        {\n            _4029 = L.b;\n        }\n        else\n        {\n            _4029 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4029, v), _4029), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4062 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4062.x) + (vec3(L.f90) * _4062.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4117 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4117.x) + _4117.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3594 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3594.x) + vec3(_3594.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _4819 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _4823 = fa_xm_origin(param_1);\n    vec2 _4829 = (uv * _4819) - vec2(0.5);\n    vec2 _4832 = fract(_4829);\n    vec2 _4835 = floor(_4829);\n    vec2 param_2 = _4819;\n    vec2 param_3 = _4823;\n    vec2 param_4 = _4835;\n    vec2 param_5 = _4819;\n    vec2 param_6 = _4823;\n    vec2 param_7 = _4835 + vec2(1.0, 0.0);\n    vec2 param_8 = _4819;\n    vec2 param_9 = _4823;\n    vec2 param_10 = _4835 + vec2(0.0, 1.0);\n    vec2 param_11 = _4819;\n    vec2 param_12 = _4823;\n    vec2 param_13 = _4835 + vec2(1.0);\n    vec3 _4877 = vec3(_4832.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4877), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4877), vec3(_4832.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _4896 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _4900 = clamp(lod, 0.0, _4896);\n    int _4904 = int(floor(_4900));\n    int param = _4904;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _4914 = float(_4904);\n    float _4915 = _4900 - _4914;\n    bool _4917 = _4915 > 0.001000000047497451305389404296875;\n    bool _4924;\n    if (_4917)\n    {\n        _4924 = _4914 < _4896;\n    }\n    else\n    {\n        _4924 = _4917;\n    }\n    if (_4924)\n    {\n        int param_2 = _4904 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_4915));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4950 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _4950.x) + (vec3(f90) * _4950.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _4978 = max(s.thickness, 0.0);\n    bool _4983 = _4978 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _4983)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _4978);\n    }\n    bool _5008 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5015;\n    if (!_5008)\n    {\n        _5015 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5015 = _5008;\n    }\n    if (_5015)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_4983)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _4978);\n    }\n    vec4 _5050 = vec4(world, 1.0);\n    float _5055 = dot(fa_mesh_fs_params[28], _5050);\n    vec2 uv = vec2(0.5);\n    if (_5055 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5073 = vec2(dot(fa_mesh_fs_params[26], _5050), dot(fa_mesh_fs_params[27], _5050)) / vec2(_5055);\n        float _5081;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5081 = (_5073.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5081 = 0.5 - (_5073.y * 0.5);\n        }\n        uv = vec2((_5073.x * 0.5) + 0.5, _5081);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3200 = int(fa_shadows[25].x + 0.5);\n    float _3210 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3215 = _3200 > 0;\n    bool _3224;\n    if (_3215)\n    {\n        int param = _3200 - 1;\n        _3224 = _3210 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3224 = _3215;\n    }\n    if (_3224)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3230 = _3200 > 1;\n        bool _3237;\n        if (_3230)\n        {\n            _3237 = _3210 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3237 = _3230;\n        }\n        if (_3237)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3243 = _3200 > 2;\n        bool _3250;\n        if (_3243)\n        {\n            _3250 = _3210 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3250 = _3243;\n        }\n        if (_3250)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3256 = _3200 > 3;\n        bool _3263;\n        if (_3256)\n        {\n            _3263 = _3210 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3263 = _3256;\n        }\n        if (_3263)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7338 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7338 = -_7338;\n    }\n    vec3 _6628 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7338, fa_world_tangent, fa_uv, fa_vertex_color, _6628, gl_FrontFacing);\n    Surface _6636 = fa_standard_surface(param_1);\n    vec3 _7369 = _6636.albedo;\n    float _7370 = _6636.alpha;\n    vec3 _7371 = _6636.normal;\n    float _7372 = _6636.metallic;\n    float _7373 = _6636.roughness;\n    float _7374 = _6636.occlusion;\n    vec3 _7375 = _6636.emission;\n    float _7376 = _6636.clearcoat;\n    float _7377 = _6636.clearcoat_roughness;\n    vec3 _7378 = _6636.sheen_color;\n    float _7379 = _6636.sheen_roughness;\n    float _7380 = _6636.anisotropy;\n    float _7381 = _6636.anisotropy_rotation;\n    float _7382 = _6636.specular;\n    float _7383 = _6636.ior;\n    vec3 _7384 = _6636.specular_color;\n    float _7385 = _6636.transmission;\n    float _7386 = _6636.thickness;\n    vec3 _7387 = _6636.attenuation_color;\n    float _7388 = _6636.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7338, fa_world_tangent, fa_uv, fa_vertex_color, _6628, gl_FrontFacing);\n    Surface param_3 = _6636;\n    surface(param_2, param_3);\n    _7369 = param_3.albedo;\n    _7370 = param_3.alpha;\n    _7371 = param_3.normal;\n    _7372 = param_3.metallic;\n    _7373 = param_3.roughness;\n    _7374 = param_3.occlusion;\n    _7375 = param_3.emission;\n    _7376 = param_3.clearcoat;\n    _7377 = param_3.clearcoat_roughness;\n    _7378 = param_3.sheen_color;\n    _7379 = param_3.sheen_roughness;\n    _7380 = param_3.anisotropy;\n    _7381 = param_3.anisotropy_rotation;\n    _7382 = param_3.specular;\n    _7383 = param_3.ior;\n    _7384 = param_3.specular_color;\n    _7385 = param_3.transmission;\n    _7386 = param_3.thickness;\n    _7387 = param_3.attenuation_color;\n    _7388 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7338;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7369 = param_6;\n    _7371 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7369;\n    }\n    else\n    {\n        vec3 _6676 = normalize(_7371);\n        float _6683 = clamp(_7372, 0.0, 1.0);\n        float _6687 = clamp(_7373, 0.0500000007450580596923828125, 1.0);\n        float _6691 = _6687 * _6687;\n        float _6695 = _6691 * _6691;\n        float _6700 = max(dot(_6676, _6628), 9.9999997473787516355514526367188e-05);\n        float _6706 = 1.0 - _6683;\n        float _6707 = clamp(_7385, 0.0, 1.0) * _6706;\n        vec3 _6716 = (_7369 * _6706) * (1.0 - _6707);\n        vec3 _6723 = mix(vec3(0.039999999105930328369140625), _7369, vec3(_6683));\n        vec3 f0 = _6723;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7338, fa_world_tangent, fa_uv, fa_vertex_color, _6628, gl_FrontFacing);\n        Surface param_9 = Surface(_7369, _7370, _7371, _7372, _7373, _7374, _7375, _7376, _7377, _7378, _7379, _7380, _7381, _7382, _7383, _7384, _7385, _7386, _7387, _7388);\n        vec3 param_10 = _6676;\n        vec3 param_11 = _6628;\n        float param_12 = _6683;\n        float param_13 = _6687;\n        vec3 param_14 = _6723;\n        FaLayers _6739 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6676;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6716) * _7374;\n        if (_6739.on)\n        {\n            lit *= _6739.base_scale;\n        }\n        int _6761 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6761; ln++)\n        {\n            int param_16 = ln;\n            int _6774 = fa_cl_light(param_16);\n            bool _6777 = fa_lm.z > 0.5;\n            bool _6783;\n            if (_6777)\n            {\n                int param_17 = _6774;\n                _6783 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6783 = _6777;\n            }\n            if (_6783)\n            {\n                continue;\n            }\n            int param_18 = _6774;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7338;\n            LightSample _6795 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6803 = max(dot(_6676, _6795.direction), 0.0);\n            float _6809 = _6795.attenuation * _6795.shadow;\n            vec3 _6814 = normalize(_6795.direction + _6628);\n            float _6819 = max(dot(_6676, _6814), 0.0);\n            float _6824 = max(dot(_6628, _6814), 0.0);\n            bool _6831;\n            if (fa_light_is_area)\n            {\n                _6831 = !_6739.on;\n            }\n            else\n            {\n                _6831 = fa_light_is_area;\n            }\n            if (_6831)\n            {\n                int param_21 = _6774;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6676;\n                vec3 param_24 = _6628;\n                vec3 param_25 = _6716;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6687;\n                float param_29 = _6700;\n                float param_30 = _6809;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6739;\n                    int param_32 = _6774;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6676;\n                    vec3 param_35 = _6628;\n                    vec3 param_36 = _6795.direction;\n                    vec3 param_37 = _6716;\n                    vec3 param_38 = f0;\n                    float param_39 = _6687;\n                    float param_40 = _6700;\n                    float param_41 = _6809;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6739.on)\n                    {\n                        FaLayers param_42 = _6739;\n                        vec3 param_43 = _6716;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6676;\n                        vec3 param_46 = _6628;\n                        vec3 param_47 = _6795.direction;\n                        vec3 param_48 = _6814;\n                        float param_49 = _6803;\n                        float param_50 = _6700;\n                        float param_51 = _6819;\n                        float param_52 = _6824;\n                        float param_53 = _6691;\n                        float param_54 = _6695;\n                        int param_55 = _6774;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6809));\n                    }\n                    else\n                    {\n                        float _6937 = ((_6819 * _6819) * (_6695 - 1.0)) + 1.0;\n                        int param_56 = _6774;\n                        lit += (((_6716 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6824, 5.0))) * (((_6695 / ((3.1415927410125732421875 * _6937) * _6937)) * (0.5 / max(mix((2.0 * _6803) * _6700, _6803 + _6700, _6691), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6803))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6803 * _6809));\n                    }\n                }\n            }\n        }\n        if (_6739.on)\n        {\n            FaLayers param_57 = _6739;\n            vec3 param_58 = _6676;\n            vec3 param_59 = _6628;\n            vec3 param_60 = f0;\n            float param_61 = _6687;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7374);\n        }\n        else\n        {\n            vec3 param_62 = _6676;\n            vec3 param_63 = _6628;\n            vec3 param_64 = f0;\n            float param_65 = _6687;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7374);\n        }\n        if (_6707 > 0.0)\n        {\n            float _7035;\n            if (_6739.on)\n            {\n                _7035 = _6739.f90;\n            }\n            else\n            {\n                _7035 = 1.0;\n            }\n            float _7043;\n            if (_6739.on)\n            {\n                _7043 = _6739.base_scale;\n            }\n            else\n            {\n                _7043 = 1.0;\n            }\n            Surface param_66 = Surface(_7369, _7370, _7371, _7372, _7373, _7374, _7375, _7376, _7377, _7378, _7379, _7380, _7381, _7382, _7383, _7384, _7385, _7386, _7387, _7388);\n            vec3 param_67 = _6676;\n            vec3 param_68 = _6628;\n            float param_69 = _6687;\n            vec3 param_70 = f0;\n            float param_71 = _7035;\n            float param_72 = _7043;\n            float param_73 = _6707;\n            float param_74 = fa_tr_blend;\n            vec3 _7067 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7067;\n        }\n        result = lit;\n    }\n    vec3 _7074 = result;\n    vec3 _7075 = _7074 + _7375;\n    result = _7075;\n    vec3 param_75 = _7075;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7084 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7091;\n    if (!_7084)\n    {\n        _7091 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7091 = _7084;\n    }\n    if (_7091)\n    {\n        vec3 _7100 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7106 = dot(_7100, fa_mesh_fs_params[9].xyz);\n        bool _7110 = fa_mesh_fs_params[9].w > 0.5;\n        float _7111;\n        if (_7110)\n        {\n            _7111 = _7106;\n        }\n        else\n        {\n            _7111 = length(_7100);\n        }\n        float _7123 = _7111 - fa_mesh_fs_params[8].x;\n        if (_7123 > 0.0)\n        {\n            float _7132 = fa_mesh_fs_params[7].w * _7123;\n            float tau = _7132 * _7132;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7148;\n                if (_7110)\n                {\n                    _7148 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7106);\n                }\n                else\n                {\n                    _7148 = fa_mesh_fs_params[0].y;\n                }\n                float _7169 = mix(_7148, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7111, 0.0, 1.0));\n                float _7173 = fa_world_pos.y - _7169;\n                float _7178 = _7169 - fa_mesh_fs_params[8].z;\n                float _7183 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7186 = _7178 <= 0.0;\n                bool _7187 = !_7186;\n                bool _7193;\n                if (_7187)\n                {\n                    _7193 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7193 = _7186;\n                }\n                float _7194;\n                if (_7193)\n                {\n                    _7194 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7194 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7178, 80.0));\n                }\n                bool _7221;\n                if (_7187)\n                {\n                    _7221 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7221 = _7186;\n                }\n                float _7222;\n                if (_7221)\n                {\n                    _7222 = fa_mesh_fs_params[8].y * _7178;\n                }\n                else\n                {\n                    _7222 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7178, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7247 = _7183 <= 0.0;\n                bool _7254;\n                if (!_7247)\n                {\n                    _7254 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7254 = _7247;\n                }\n                float _7255;\n                if (_7254)\n                {\n                    _7255 = fa_mesh_fs_params[8].y * _7183;\n                }\n                else\n                {\n                    _7255 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7183, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7282;\n                if (abs(_7173) < 0.001000000047497451305389404296875)\n                {\n                    _7282 = _7194;\n                }\n                else\n                {\n                    _7282 = (_7255 - _7222) / _7173;\n                }\n                tau += (_7123 * max(_7282, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _7318 = 1.0 - fa_tr_blend;\n        result /= vec3(_7318);\n        _7370 *= _7318;\n    }\n    fa_frag_color = vec4(result, _7370);\n}\n\n",
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
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_597",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
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
            "inst_name": "_2264",
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
            "inst_name": "_6233",
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
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 7) out vec3 fa_lm;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3694[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[32];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1535 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1542;\n    if (!_1535)\n    {\n        _1542 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1542 = _1535;\n    }\n    bool _1550;\n    if (!_1542)\n    {\n        _1550 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1550 = _1542;\n    }\n    bool _1557;\n    if (!_1550)\n    {\n        _1557 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1557 = _1550;\n    }\n    bool _1564;\n    if (!_1557)\n    {\n        _1564 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1564 = _1557;\n    }\n    if (_1564)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1574 = vec4(world_pos, 1.0);\n    float _1580 = dot(fa_mesh_fs_params[16], _1574);\n    if (!(_1580 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1602 = vec2(dot(fa_mesh_fs_params[14], _1574), dot(fa_mesh_fs_params[15], _1574)) / vec2(_1580);\n    int _1606 = int(fa_mesh_fs_params[18].x);\n    int _1610 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1610) + clamp(int(floor(((_1602.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1610 - 1)) * _1606)) + clamp(int(floor(((_1602.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1606 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1686 = fa_cluster_texel(param);\n    return ivec2(int(_1686.x), int(_1686.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5127 = fa_cluster_lookup(param);\n    fa_cl_slot = _5127.x;\n    fa_cl_local = _5127.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6285 = fa_linear_to_srgb(param);\n        c = _6285;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6293 = fa_srgb_to_linear(param_1);\n            c = _6293;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _480;\n    if (i.front_facing)\n    {\n        _480 = i.world_normal;\n    }\n    else\n    {\n        _480 = -i.world_normal;\n    }\n    vec3 _504 = normalize(i.world_tangent.xyz - (_480 * dot(_480, i.world_tangent.xyz)));\n    vec3 _531 = normalize(((_504 * m.x) + ((cross(_480, _504) * i.world_tangent.w) * m.y)) + (_480 * m.z));\n    vec3 _534;\n    if (i.front_facing)\n    {\n        _534 = _531;\n    }\n    else\n    {\n        _534 = -_531;\n    }\n    return _534;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6324 = fa_tex_fix(param_2, param_3);\n    vec4 _7890 = base_t;\n    _7890.x = _6324.x;\n    _7890.y = _6324.y;\n    _7890.z = _6324.z;\n    base_t = _7890;\n    vec4 _6338 = (_7890 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7699 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6370 = fa_tex_fix(param_6, param_7);\n        vec3 _6373 = (_6370 * 2.0) - vec3(1.0);\n        vec2 _6378 = _6373.xy * fa_mesh_fs_params[6].x;\n        vec3 _7898 = _6373;\n        _7898.x = _6378.x;\n        _7898.y = _6378.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7898;\n        _7699 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6406 = fa_tex_fix(param_12, param_13);\n    vec4 _7901 = mrt;\n    _7901.x = _6406.x;\n    _7901.y = _6406.y;\n    _7901.z = _6406.z;\n    mrt = _7901;\n    vec4 _6434 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6434.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6445 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6475 = fa_tex_fix(param_20, param_21);\n    float _7704 = fa_mesh_fs_params[20].x;\n    float _7705 = fa_mesh_fs_params[20].y;\n    float _7708 = fa_mesh_fs_params[20].z;\n    float _7707 = fa_mesh_fs_params[21].w;\n    float _7710 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7704 *= _6445.y;\n            _7705 *= _6445.z;\n            _7707 *= _6434.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7708 *= mrt.x;\n            _7710 *= mrt.w;\n        }\n    }\n    return Surface(_6338.xyz, _6338.w, _7699, clamp(fa_mesh_fs_params[5].x * _6406.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6406.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6445.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6475), _7704, _7705, fa_mesh_fs_params[21].xyz, _7707, _7708, fa_mesh_fs_params[20].w, _7710, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1766 = rect.zw - rect.xy;\n    vec2 _1770 = _1766 * atlas;\n    vec2 _1774 = ddx * _1770;\n    vec2 _1778 = ddy * _1770;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1766), clamp(0.5 * log2(max(max(dot(_1774, _1774), dot(_1778, _1778)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1811 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1818;\n    if (!_1811)\n    {\n        _1818 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1818 = _1811;\n    }\n    if (_1818)\n    {\n        return;\n    }\n    vec3 _1824 = dFdx(world_pos);\n    vec3 _1827 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1831 = fa_cluster_texel(param);\n    int _1835 = int(_1831.w);\n    if (_1835 < 1)\n    {\n        return;\n    }\n    int _1845 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1845;\n    vec4 _1849 = fa_light_texel(param_1);\n    vec2 _1852 = _1849.yz;\n    int _1856 = int(_1849.w);\n    int param_2 = _1845 + 1;\n    vec4 _1861 = fa_light_texel(param_2);\n    float _1862 = _1861.x;\n    int _1868 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1872 = int(_1831.z);\n    vec3 _2137;\n    for (int k = 0; k < _1835; k++)\n    {\n        int _1885 = _1872 + k;\n        int param_3 = _1856 + (_1885 >> 2);\n        int _1902 = (_1845 + 2) + (int(fa_light_texel(param_3)[_1885 & 3]) * 7);\n        int param_4 = _1902 + 6;\n        vec4 _1907 = fa_light_texel(param_4);\n        if (((int(_1907.w + 0.5) >> _1868) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1902;\n        vec4 _1922 = fa_light_texel(param_5);\n        int param_6 = _1902 + 1;\n        vec4 _1927 = fa_light_texel(param_6);\n        int param_7 = _1902 + 2;\n        vec4 _1932 = fa_light_texel(param_7);\n        vec3 _1935 = _1922.xyz;\n        float _1940 = dot(_1935, world_pos) + _1922.w;\n        vec3 _1942 = _1927.xyz;\n        float _1947 = dot(_1942, world_pos) + _1927.w;\n        vec3 _1949 = _1932.xyz;\n        float _1954 = dot(_1949, world_pos) + _1932.w;\n        bool _1959 = abs(_1940) > 0.5;\n        bool _1967;\n        if (!_1959)\n        {\n            _1967 = abs(_1947) > 0.5;\n        }\n        else\n        {\n            _1967 = _1959;\n        }\n        bool _1975;\n        if (!_1967)\n        {\n            _1975 = abs(_1954) > 0.5;\n        }\n        else\n        {\n            _1975 = _1967;\n        }\n        if (_1975)\n        {\n            continue;\n        }\n        float _1990 = clamp(dot(geo_normal, normalize(_1949)) * _1907.z, 0.0, 1.0);\n        if (_1990 <= 0.0)\n        {\n            continue;\n        }\n        float _2010 = (clamp((0.5 - abs(_1954)) * 10.0, 0.0, 1.0) * _1990) * _1907.x;\n        vec2 _2018 = vec2(_1940 + 0.5, 0.5 - _1947);\n        vec2 _2028 = vec2(dot(_1935, _1824), dot(_1942, _1824));\n        vec2 _2038 = vec2(dot(_1935, _1827), dot(_1942, _1827));\n        int param_8 = _1902 + 5;\n        vec4 _2043 = fa_light_texel(param_8);\n        int param_9 = _1902 + 3;\n        vec4 _2048 = fa_light_texel(param_9);\n        int param_10 = _1902 + 4;\n        vec4 _2053 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2043.xyz;\n        bool _2063 = _2048.z > _2048.x;\n        if (_2063)\n        {\n            vec4 param_11 = _2048;\n            vec2 param_12 = _2018;\n            vec2 param_13 = _1852;\n            vec2 param_14 = _2028;\n            vec2 param_15 = _2038;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1862 > 0.5) && (_1862 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2089 = fa_dc_to_linear(param_16);\n                vec4 _7787 = tx;\n                _7787.x = _2089.x;\n                _7787.y = _2089.y;\n                _7787.z = _2089.z;\n                tx = _7787;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2010 * tex_a) * _2043.w, 0.0, 1.0)));\n        if (_2053.z > _2053.x)\n        {\n            vec4 param_17 = _2053;\n            vec2 param_18 = _2018;\n            vec2 param_19 = _1852;\n            vec2 param_20 = _2028;\n            vec2 param_21 = _2038;\n            vec4 _2133 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1862 > 1.5)\n            {\n                vec3 param_22 = _2133.xyz;\n                vec3 _2143 = fa_dc_to_srgb(param_22);\n                _2137 = _2143;\n            }\n            else\n            {\n                _2137 = _2133.xyz;\n            }\n            vec3 _2152 = (_2137 * 2.0) - vec3(1.0);\n            vec2 _2157 = _2152.xy * _1907.y;\n            vec3 _2179 = (normalize(_1935) * _2157.x) + (normalize(_1942) * _2157.y);\n            vec3 _2182 = normalize(normal);\n            normal = normalize(mix(_2182, normalize((_2182 * max(_2152.z, 0.0500000007450580596923828125)) + (_2179 - (_2182 * dot(_2182, _2179)))), vec3(clamp(_2010 * (_2063 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3620 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3627 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3630 = int(_3620);\n    int _3633 = int(_3627);\n    float _3643 = _3627 - float(_3633);\n    int _3698 = (_3630 * 9) + _3633;\n    int _3718 = ((_3630 + 1) * 9) + _3633;\n    return mix(mix(_3694[_3698], _3694[_3698 + 1], _3643), mix(_3694[_3718], _3694[_3718 + 1], _3643), _3620 - float(_3630));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7622 = false;\n    float _7623 = 1.0;\n    float _7624 = 1.0;\n    float _7625 = 1.0;\n    float _7626 = 0.0;\n    float _7627 = 0.0;\n    float _7628 = 0.0;\n    float _7629 = 0.0;\n    float _7631 = 1.0;\n    bool _7632 = false;\n    vec3 _7633 = vec3(0.0);\n    float _7634 = 1.0;\n    float _7635 = 1.0;\n    float _7636 = 1.0;\n    float _7637 = 0.0;\n    float _7638 = 0.0;\n    vec3 _7639 = vec3(1.0, 0.0, 0.0);\n    vec3 _7640 = vec3(0.0, 0.0, 1.0);\n    float _7641 = 1.0;\n    float _7642 = 1.0;\n    float _3769 = clamp(s.specular, 0.0, 1.0);\n    float _3773 = clamp(s.ior, 1.0, 3.0);\n    bool _3778 = (_3769 != 1.0) || (_3773 != 1.5);\n    bool _3787;\n    if (!_3778)\n    {\n        _3787 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3787 = _3778;\n    }\n    if (_3787)\n    {\n        float _3795 = (_3773 - 1.0) / (_3773 + 1.0);\n        f0 = mix(min(vec3(_3795 * _3795) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3769, s.albedo, vec3(metallic));\n        _7623 = mix(_3769, 1.0, metallic);\n        _7622 = true;\n    }\n    float _3822 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3822 > 0.0)\n    {\n        float _3830 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7626 = _3822;\n        _7627 = _3830;\n        float _3837 = _3830 * _3830;\n        _7628 = _3837;\n        _7629 = _3837 * _3837;\n        float _3849 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7631 = _3849;\n        _7624 = 1.0 - (_3822 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3849, 0.0, 1.0), 5.0))));\n        _7622 = true;\n    }\n    vec3 _3868 = max(s.sheen_color, vec3(0.0));\n    float _3877 = max(_3868.x, max(_3868.y, _3868.z));\n    if (_3877 > 0.0)\n    {\n        float _3885 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7632 = true;\n        _7633 = _3868;\n        _7634 = _3885;\n        _7635 = _3885 * _3885;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3885;\n        float _3902 = fa_sheen_albedo(param, param_1);\n        _7637 = _3902;\n        _7636 = 1.0 - min(_3877 * _3902, 1.0);\n        _7622 = true;\n    }\n    _7625 = _7624 * _7636;\n    float _3921 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3921 != 0.0)\n    {\n        vec3 _3936 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3936;\n        if (dot(_3936, _3936) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3948 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3948.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3948.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3948.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3952 = t;\n        vec3 _3953 = normalize(_3952);\n        t = _3953;\n        vec3 _3978 = normalize((_3953 * cos(s.anisotropy_rotation)) + ((cross(n, _3953) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7639 = _3978;\n        _7640 = cross(n, _3978);\n        float _3988 = roughness * roughness;\n        float _3994 = mix(_3988, 1.0, _3921 * _3921);\n        bool _3996 = _3921 > 0.0;\n        _7641 = _3996 ? _3994 : _3988;\n        _7642 = _3996 ? _3988 : _3994;\n        _7638 = _3921;\n        _7622 = true;\n    }\n    return FaLayers(_7622, _7623, _7624, _7625, _7626, _7627, _7628, _7629, i.world_normal, _7631, _7632, _7633, _7634, _7635, _7636, _7637, _7638, _7639, _7640, _7641, _7642);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3377 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3377;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    vec3 param = n;\n    return fa_ambient_light(param);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _784 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _797 = (c - (ru * hx)) - p;\n        vec3 _803 = ru * (2.0 * hx);\n        float _809 = max(dot(_803, _803), 9.9999999392252902907785028219223e-09);\n        float _813 = dot(_797, _803);\n        float t = clamp((-_813) / _809, 0.0, 1.0);\n        if (_784)\n        {\n            float _828 = dot(r, _803);\n            float _834 = _809 - (_828 * _828);\n            if (abs(_834) > (9.9999997473787516355514526367188e-06 * _809))\n            {\n                t = clamp(((dot(r, _797) * _828) - _813) / _834, 0.0, 1.0);\n            }\n        }\n        return (p + _797) + (_803 * t);\n    }\n    vec3 q = p;\n    float _866 = dot(r, axis);\n    bool _874;\n    if (_784)\n    {\n        _874 = abs(_866) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _874 = _784;\n    }\n    if (_874)\n    {\n        float _884 = dot(c - p, axis) / _866;\n        if (_884 > 0.0)\n        {\n            q = p + (r * _884);\n        }\n    }\n    vec3 _897 = q - c;\n    vec2 xy = vec2(dot(_897, ru), dot(_897, uu));\n    if (shape > 0.5)\n    {\n        float _912 = length(xy);\n        if (_912 > hx)\n        {\n            xy *= (hx / _912);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _546 = abs(d);\n    float _548 = _546.x;\n    float _550 = _546.y;\n    bool _551 = _548 >= _550;\n    bool _559;\n    if (_551)\n    {\n        _559 = _548 >= _546.z;\n    }\n    else\n    {\n        _559 = _551;\n    }\n    int _560;\n    if (_559)\n    {\n        _560 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _575;\n        if (_550 >= _546.z)\n        {\n            _575 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _575 = (d.z > 0.0) ? 4 : 5;\n        }\n        _560 = _575;\n    }\n    return _560;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _704 = dot(d, right);\n    float _708 = dot(d, up);\n    float _719;\n    if (((_704 * _704) + (_708 * _708)) > 1.0000000133514319600180897396058e-10)\n    {\n        _719 = atan(_708, _704) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _719 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_719 - floor(_719)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _950 = fa_light_base(param);\n    bool _954 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _950;\n    vec4 _958 = fa_light_texel(param_1);\n    int param_2 = _950 + 1;\n    vec4 _963 = fa_light_texel(param_2);\n    float _966 = _963.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _978 = _954 && (_966 > 2.5);\n    fa_light_is_area = _978;\n    bool _980 = _966 < 0.5;\n    vec3 l;\n    if (_980)\n    {\n        l = normalize(_958.xyz);\n        if (_954)\n        {\n            int param_3 = _950 + 6;\n            vec4 _994 = fa_light_texel(param_3);\n            if (_994.z > 0.5)\n            {\n                int param_4 = _950 + 4;\n                vec4 _1004 = fa_light_texel(param_4);\n                int param_5 = _950 + 5;\n                vec4 _1009 = fa_light_texel(param_5);\n                vec2 param_6 = _994.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1004.xyz) * _1004.w, (-dot(world_pos, _1009.xyz)) * _1009.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1039 = _958.xyz;\n        vec3 _1041 = _1039 - world_pos;\n        vec3 to_light = _1041;\n        float _1044 = length(_1041);\n        float reach = _1044;\n        bool front = true;\n        if (_978)\n        {\n            int param_8 = _950 + 7;\n            reach = max(_1044 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _950 + 4;\n            vec4 _1068 = fa_light_texel(param_9);\n            int param_10 = _950 + 5;\n            vec4 _1073 = fa_light_texel(param_10);\n            int param_11 = _950 + 6;\n            vec4 _1078 = fa_light_texel(param_11);\n            float _1079 = _1078.w;\n            int param_12 = _950 + 2;\n            vec3 _1086 = normalize(fa_light_texel(param_12).xyz);\n            bool _1088 = _1079 > 1.5;\n            bool _1096;\n            if (!_1088)\n            {\n                _1096 = dot(_1086, to_light) < 0.0;\n            }\n            else\n            {\n                _1096 = _1088;\n            }\n            front = _1096;\n            vec3 r = vec3(0.0);\n            vec3 _1105 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1109 = dot(n, n) > 0.5;\n            bool _1117;\n            if (_1109)\n            {\n                _1117 = dot(_1105, _1105) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1117 = _1109;\n            }\n            if (_1117)\n            {\n                r = reflect(-normalize(_1105), normalize(n));\n            }\n            vec3 param_13 = _1039;\n            vec3 param_14 = _1086;\n            vec3 param_15 = _1068.xyz;\n            vec3 param_16 = _1073.xyz;\n            float param_17 = _1068.w;\n            float param_18 = _1073.w;\n            float param_19 = _1079;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1153 = length(to_light);\n        dist = _1153;\n        l = to_light / vec3(max(_1153, 9.9999997473787516355514526367188e-05));\n        float _1167 = reach / max(_958.w, 0.001000000047497451305389404296875);\n        float _1173 = clamp(1.0 - (_1167 * _1167), 0.0, 1.0);\n        float _1175;\n        if (front)\n        {\n            _1175 = _1173 * _1173;\n        }\n        else\n        {\n            _1175 = 0.0;\n        }\n        atten = _1175;\n        bool _1186 = _966 < 2.5;\n        if ((_966 > 1.5) && _1186)\n        {\n            int param_22 = _950 + 2;\n            vec4 _1194 = fa_light_texel(param_22);\n            float _1204 = _1194.w;\n            int param_23 = _950 + 3;\n            vec4 _1209 = fa_light_texel(param_23);\n            float _1210 = _1209.x;\n            float cos_inner = _1210;\n            if (_1210 > 1.5)\n            {\n                cos_inner = mix(_1204, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1204, cos_inner, dot(-l, normalize(_1194.xyz)));\n        }\n        if (_954 && (_966 < 1.5))\n        {\n            int param_24 = _950 + 6;\n            vec4 _1234 = fa_light_texel(param_24);\n            if (_1234.z > 0.5)\n            {\n                vec3 _1242 = -to_light;\n                int param_25 = _950 + 4;\n                int param_26 = _950 + 5;\n                vec3 _1256 = fa_light_texel(param_25).xyz;\n                vec3 _1260 = fa_light_texel(param_26).xyz;\n                vec3 _1269 = vec3(dot(_1242, _1256), dot(_1242, _1260), dot(_1242, cross(_1256, _1260)));\n                vec3 param_27 = _1269;\n                int _1273 = fa_cube_face(param_27);\n                int param_28 = _1273;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1300 = vec2(dot(_1269, cross(param_29, param_30)), dot(_1269, param_30)) / vec2(max(dot(_1269, param_29), 9.9999997473787516355514526367188e-05));\n                int _1304 = _1273 / 3;\n                vec2 param_31 = _1234.xy + (vec2(float(_1273 - (_1304 * 3)), float(_1304)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1300.x), 0.5 - (0.5 * _1300.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _950 + 7;\n            vec4 _1334 = fa_light_texel(param_33);\n            if (_1334.z > 0.5)\n            {\n                int param_34 = _950 + 2;\n                int param_35 = _950 + 4;\n                int param_36 = _950 + 5;\n                vec2 param_37 = _1334.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_954 && _1186)\n            {\n                int param_42 = _950 + 6;\n                vec4 _1381 = fa_light_texel(param_42);\n                int param_43 = _950 + 7;\n                vec4 _1386 = fa_light_texel(param_43);\n                bool _1389 = _1381.z > 0.5;\n                bool _1396;\n                if (!_1389)\n                {\n                    _1396 = _1386.z > 0.5;\n                }\n                else\n                {\n                    _1396 = _1389;\n                }\n                if (_1396)\n                {\n                    int param_44 = _950 + 2;\n                    vec4 _1403 = fa_light_texel(param_44);\n                    vec3 _1407 = normalize(_1403.xyz);\n                    int param_45 = _950 + 4;\n                    vec4 _1412 = fa_light_texel(param_45);\n                    int param_46 = _950 + 5;\n                    vec4 _1417 = fa_light_texel(param_46);\n                    if (_1389)\n                    {\n                        vec3 _1425 = -to_light;\n                        float _1432 = _1403.w;\n                        float _1448 = 0.5 / max(dot(_1425, _1407) * (sqrt(max(1.0 - (_1432 * _1432), 0.0)) / max(_1432, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1381.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1425, _1412.xyz) * _1448), 0.5 - (dot(_1425, _1417.xyz) * _1448));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1386.z > 0.5)\n                    {\n                        vec2 param_49 = _1386.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1407;\n                        vec3 param_52 = _1412.xyz;\n                        vec3 param_53 = _1417.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7610 = _963.xyz * atten;\n    if (_954)\n    {\n        _7610 *= fa_light_tint;\n    }\n    int _1517;\n    if (_980)\n    {\n        _1517 = 0;\n    }\n    else\n    {\n        _1517 = ((_966 > 1.5) && (_966 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7610, atten, 1.0, dist, _1517);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2254;\n    if (i == 0)\n    {\n        _2254 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2270;\n        if (i == 1)\n        {\n            _2270 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2278;\n            if (i == 2)\n            {\n                _2278 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2278 = fa_shadows[24].w;\n            }\n            _2270 = _2278;\n        }\n        _2254 = _2270;\n    }\n    return _2254;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2311 = fa_shadow_depth(param, param_1);\n    float _2315;\n    if (conv.x < 0.5)\n    {\n        _2315 = _2311;\n    }\n    else\n    {\n        _2315 = (conv.y * conv.z) / (conv.z - (_2311 * (conv.z - conv.y)));\n    }\n    return _2315;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2242 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2242), sin(_2242)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2361 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2370;\n        if (k < 0.0)\n        {\n            _2370 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2370 = k;\n        }\n        float _2390 = clamp((_2370 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2361;\n            vec2 _2409 = fa_shadow_vogel(param_3, param_4, param_5) * _2390;\n            vec2 param_6 = uv + (_2409 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2421 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2421 < (zr - (length(_2409) * plane)))\n            {\n                sum += _2421;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2447 = sum / cnt;\n        float _2457;\n        if (k < 0.0)\n        {\n            _2457 = (-k) / max(_2447, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2457 = k;\n        }\n        radius = clamp(((max(zr - _2447, 0.0) * unit) * _2457) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2479 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2479; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2479;\n        float param_11 = _2361;\n        vec2 _2498 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2498 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2498) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2479);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2540 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2545 = clamp(dot(n, l), 0.0, 1.0);\n    float _2551 = sqrt(1.0 - (_2545 * _2545));\n    float _2558 = min(_2551 / max(_2545, 0.20000000298023223876953125), 4.0);\n    float _2563;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2563 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2563 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2588 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2563 * _2551)), 1.0);\n    float _2595 = _2588.x;\n    bool _2598 = _2595 < fa_shadows[ci * 1 + 16].x;\n    bool _2607;\n    if (!_2598)\n    {\n        _2607 = _2595 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2607 = _2598;\n    }\n    bool _2616;\n    if (!_2607)\n    {\n        _2616 = _2588.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2616 = _2607;\n    }\n    bool _2625;\n    if (!_2616)\n    {\n        _2625 = _2588.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2625 = _2616;\n    }\n    bool _2632;\n    if (!_2625)\n    {\n        _2632 = _2588.z > 1.0;\n    }\n    else\n    {\n        _2632 = _2625;\n    }\n    if (_2632)\n    {\n        return -1.0;\n    }\n    float _2640;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2640 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2640 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2588.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2588.z - ((_2640 * (1.0 + (0.5 * _2558))) / _2540);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2540;\n    float param_5 = _2540 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2558, 3.0)) * 0.5) / _2540;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3018 = int(fa_shadows[25].x + 0.5);\n    if (_3018 < 1)\n    {\n        return 1.0;\n    }\n    float _3033 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3018 - 1;\n    if (_3033 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3045 = _3018 > 1;\n    bool _3052;\n    if (_3045)\n    {\n        _3052 = _3033 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3052 = _3045;\n    }\n    if (_3052)\n    {\n        ci = 1;\n    }\n    bool _3056 = _3018 > 2;\n    bool _3063;\n    if (_3056)\n    {\n        _3063 = _3033 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3063 = _3056;\n    }\n    if (_3063)\n    {\n        ci = 2;\n    }\n    bool _3067 = _3018 > 3;\n    bool _3074;\n    if (_3067)\n    {\n        _3074 = _3033 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3074 = _3067;\n    }\n    if (_3074)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3018)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3100 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3100;\n        if (_3100 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3125;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3125 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3125 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3144 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3125, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3155 = clamp((_3033 - (fa_shadow_split_at(param_7) - _3144)) / _3144, 0.0, 1.0);\n        if (_3155 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3018)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3176 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3176;\n                if (_3176 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3155);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2698 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2705;\n    if (!_2698)\n    {\n        _2705 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2705 = _2698;\n    }\n    if (_2705)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2718 = fa_light_texel(param);\n    float _2719 = _2718.x;\n    if (_2719 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2728 = int(_2719 + 0.5);\n    int param_1 = _2728;\n    vec4 _2732 = fa_light_texel(param_1);\n    int param_2 = _2728 + 1;\n    vec4 _2737 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2740 = _2732.y;\n    if (_2740 > 0.0)\n    {\n        float _2757 = 1.0 - smoothstep(0.75 * _2740, _2740, length(world - fa_shadows[27].xyz));\n        fade = _2757;\n        if (_2757 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2732.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2781 = (_2728 + 2) + (face * 6);\n    int param_4 = _2781;\n    int param_5 = _2781 + 1;\n    int param_6 = _2781 + 3;\n    vec4 _2795 = fa_light_texel(param_6);\n    int param_7 = _2781 + 4;\n    vec4 _2800 = fa_light_texel(param_7);\n    int param_8 = _2781 + 5;\n    vec4 _2805 = fa_light_texel(param_8);\n    float _2817 = _2805.x * max(dot(_2795, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2822 = clamp(dot(n, l), 0.0, 1.0);\n    float _2845 = clamp(dot(n, _2795.xyz), -1.0, 1.0);\n    float _2864 = min(sqrt(1.0 - (_2845 * _2845)) / max(abs(dot(n, world - lpos)) / max(dot(_2795, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2867 = _2737.y;\n    float _2869;\n    if (_2867 > 0.0)\n    {\n        _2869 = _2867;\n    }\n    else\n    {\n        _2869 = 1.5 * _2817;\n    }\n    vec4 _2889 = vec4(world + (n * (_2869 * sqrt(1.0 - (_2822 * _2822)))), 1.0);\n    float _2893 = dot(_2795, _2889);\n    float _2896 = _2805.y;\n    if (_2893 < _2896)\n    {\n        return 1.0;\n    }\n    vec2 _2911 = vec2(dot(fa_light_texel(param_4), _2889), dot(fa_light_texel(param_5), _2889)) / vec2(_2893);\n    float _2913 = _2911.x;\n    bool _2916 = _2913 < _2800.x;\n    bool _2925;\n    if (!_2916)\n    {\n        _2925 = _2913 > _2800.z;\n    }\n    else\n    {\n        _2925 = _2916;\n    }\n    bool _2934;\n    if (!_2925)\n    {\n        _2934 = _2911.y < _2800.y;\n    }\n    else\n    {\n        _2934 = _2925;\n    }\n    bool _2943;\n    if (!_2934)\n    {\n        _2943 = _2911.y > _2800.w;\n    }\n    else\n    {\n        _2943 = _2934;\n    }\n    if (_2943)\n    {\n        return 1.0;\n    }\n    float _2949 = _2737.x;\n    float _2951;\n    if (_2949 > 0.0)\n    {\n        _2951 = _2949;\n    }\n    else\n    {\n        _2951 = 1.5 * _2817;\n    }\n    vec2 param_9 = _2911;\n    vec4 param_10 = _2800;\n    float param_11 = _2893 - (_2951 * (1.0 + (0.5 * _2864)));\n    float param_12 = _2817;\n    float param_13 = 1.0;\n    float param_14 = _2805.z * 0.25;\n    float param_15 = (_2817 * min(_2864, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2896, _2805.z);\n    int param_17 = int(_2732.z + 0.5);\n    float param_18 = _2732.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4506 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4513;\n    if (!_4506)\n    {\n        _4513 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4513 = _4506;\n    }\n    if (_4513)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4526 = fa_light_texel(param);\n    float _4527 = _4526.y;\n    float len = _4527;\n    if (_4527 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4539 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4549 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4539);\n    if (_4549 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4555 = len;\n    float _4558 = min(_4555, 0.89999997615814208984375 * dist);\n    len = _4558;\n    float _4563 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4539);\n    float _4568 = _4563 + (0.5 * _4558);\n    vec3 _4574 = world + (gn * _4563);\n    float _4576 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4640;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4591 = (float(k) + _4576) * 0.083333335816860198974609375;\n        vec3 _4599 = _4574 + (l * (_4591 * len));\n        vec4 _4605 = vec4(_4599, 1.0);\n        float _4611 = dot(fa_mesh_fs_params[28], _4605);\n        if (_4611 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4631 = vec2(dot(fa_mesh_fs_params[26], _4605), dot(fa_mesh_fs_params[27], _4605)) / vec2(_4611);\n        float _4635 = _4631.x * 0.5;\n        float _4636 = _4635 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4640 = (_4631.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4640 = 0.5 - (_4631.y * 0.5);\n        }\n        bool _4656 = _4636 < 0.0;\n        bool _4663;\n        if (!_4656)\n        {\n            _4663 = _4636 >= 1.0;\n        }\n        else\n        {\n            _4663 = _4656;\n        }\n        bool _4670;\n        if (!_4663)\n        {\n            _4670 = _4640 < 0.0;\n        }\n        else\n        {\n            _4670 = _4663;\n        }\n        bool _4677;\n        if (!_4670)\n        {\n            _4677 = _4640 >= 1.0;\n        }\n        else\n        {\n            _4677 = _4670;\n        }\n        if (_4677)\n        {\n            break;\n        }\n        vec4 _4696 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4636, _4640) * fa_mesh_fs_params[24].zw), 0);\n        if (_4696.w < 0.5)\n        {\n            continue;\n        }\n        float _4715 = (dot(fa_mesh_fs_params[29].xyz, _4599) + fa_mesh_fs_params[29].w) - _4696.x;\n        if ((_4715 > _4563) && (_4715 < _4568))\n        {\n            occ = max(occ, (1.0 - (_4591 * _4591)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4636, 0.5 - _4635), min(_4640, 1.0 - _4640))));\n        }\n    }\n    return 1.0 - (occ * _4549);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    bool _5154 = fa_lm.z > 0.5;\n    bool _5160;\n    if (_5154)\n    {\n        int param = li;\n        _5160 = fa_light_baked(param);\n    }\n    else\n    {\n        _5160 = _5154;\n    }\n    if (_5160)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5184 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7679 = _5184.color;\n    float _7681 = _5184.shadow;\n    bool _5187 = _5184.type == 0;\n    if (_5187 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5184.direction;\n        float _5198 = fa_shadow_factor(param_5, param_6);\n        _7681 = _5198;\n        _7679 *= _5198;\n    }\n    else\n    {\n        bool _5209 = _5184.type != 0;\n        bool _5215;\n        if (_5209)\n        {\n            _5215 = _5184.attenuation > 0.0;\n        }\n        else\n        {\n            _5215 = _5209;\n        }\n        if (_5215)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5184.direction;\n            float _5234 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7681 = _5234;\n            _7679 *= _5234;\n        }\n    }\n    bool _5244 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5250;\n    if (_5244)\n    {\n        _5250 = _5184.attenuation > 0.0;\n    }\n    else\n    {\n        _5250 = _5244;\n    }\n    if (_5250)\n    {\n        float _5257;\n        if (_5187)\n        {\n            _5257 = 1000000000.0;\n        }\n        else\n        {\n            _5257 = _5184._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5184.direction;\n        float param_18 = _5257;\n        float _5275 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7681 *= _5275;\n        _7679 *= _5275;\n    }\n    return LightSample(_5184.direction, _7679, _5184.attenuation, _7681, _5184._distance, _5184.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5318 = v - (n * dot(v, n));\n    vec3 t = _5318;\n    float _5322 = dot(_5318, _5318);\n    float l2 = _5322;\n    if (_5322 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5332;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5332 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5332 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5332;\n        l2 = dot(_5332, _5332);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5367 = dot(a, a);\n    float _5371 = dot(b, b);\n    if ((_5367 < 1.0000000195414813782625560981111e-24) || (_5371 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5385 = a * inversesqrt(_5367);\n    vec3 _5390 = b * inversesqrt(_5371);\n    float _5394 = dot(_5385, _5390);\n    float _5397 = abs(_5394);\n    float g = (((((((((((0.0416471660137176513671875 * _5397) - 0.1924748718738555908203125) * _5397) + 0.4179156124591827392578125) * _5397) - 0.616057217121124267578125) * _5397) + 0.777722418308258056640625) * _5397) - 0.999542415142059326171875) * _5397) + 1.570791721343994140625;\n    if (_5394 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5394 * _5394), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5385, _5390) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5454 = a.z > 0.0;\n    bool _5458 = b.z > 0.0;\n    if (_5454 && _5458)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5454 != _5458)\n        {\n            vec3 _5493 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5493.z = 0.0;\n            if (_5454)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5493;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5493;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5493;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5493;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5542 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5568 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5594 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5620 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5542;\n    vec3 param_1 = _5568;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5568;\n    vec3 param_7 = _5594;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5594;\n    vec3 param_13 = _5620;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5620;\n    vec3 param_19 = _5542;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5769 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5793 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5809 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5769;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5793;\n    vec4 param_9 = m;\n    vec3 param_10 = _5769;\n    vec3 param_11 = _5793;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5809;\n    vec4 param_14 = m;\n    vec3 param_15 = _5769;\n    vec3 param_16 = _5809;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5867 = fa_light_base(param);\n    int param_1 = _5867;\n    int param_2 = _5867 + 1;\n    int param_3 = _5867 + 2;\n    int param_4 = _5867 + 4;\n    vec4 _5889 = fa_light_texel(param_4);\n    int param_5 = _5867 + 5;\n    vec4 _5894 = fa_light_texel(param_5);\n    int param_6 = _5867 + 6;\n    vec4 _5899 = fa_light_texel(param_6);\n    float _5900 = _5899.w;\n    vec3 _5905 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5907 = _5900 < 1.5;\n    bool _5914;\n    if (_5907)\n    {\n        _5914 = dot(normalize(fa_light_texel(param_3).xyz), _5905) >= 0.0;\n    }\n    else\n    {\n        _5914 = _5907;\n    }\n    if (_5914)\n    {\n        return vec3(0.0);\n    }\n    bool _5923 = (_5900 > 0.5) && _5907;\n    float _5927 = _5923 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5930 = _5889.xyz;\n    float _5932 = _5889.w;\n    vec3 _5938 = _5894.xyz;\n    float _5940 = _5894.w;\n    vec3 up = _5938 * (_5940 * _5927);\n    float _5946;\n    if (_5923)\n    {\n        _5946 = (3.1415927410125732421875 * _5932) * _5932;\n    }\n    else\n    {\n        _5946 = (4.0 * _5932) * _5940;\n    }\n    if (_5900 > 1.5)\n    {\n        vec3 _5972 = cross(_5930, -_5905);\n        vec3 perp = _5972;\n        float _5976 = dot(_5972, _5972);\n        vec3 _5979;\n        if (_5976 > 1.0000000133514319600180897396058e-10)\n        {\n            _5979 = perp * inversesqrt(_5976);\n        }\n        else\n        {\n            _5979 = _5938;\n        }\n        perp = _5979;\n        up = _5979 * _5940;\n    }\n    float _6000 = max(_5946, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6010 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6010;\n    vec3 param_10 = n;\n    vec3 param_11 = _5905;\n    vec3 _6018 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6010;\n    vec3 param_13 = n;\n    vec3 param_14 = _5930 * (_5932 * _5927);\n    vec3 _6026 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6010;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6034 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5900;\n    vec3 param_20 = _6018;\n    vec3 param_21 = _6026;\n    vec3 param_22 = _6034;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6053 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6053;\n    vec2 param_26 = _6053 + vec2(64.0, 0.0);\n    vec4 _6063 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5900;\n    vec3 param_29 = _6018;\n    vec3 param_30 = _6026;\n    vec3 param_31 = _6034;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6063.x) + ((vec3(f90) - f0) * _6063.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5905, _5905)) + _6000) / _6000) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4243 = 1.0 / alpha;\n    return ((2.0 + _4243) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4243)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4278 = max(dot(L.nc, l), 0.0);\n    float _4284 = max(dot(L.nc, h), 0.0);\n    float _4293 = ((_4284 * _4284) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4293) * _4293)) * (0.5 / max(mix((2.0 * _4278) * L.coat_ndv, _4278 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4278)) * _4278;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6131;\n    if (L.sheen_on)\n    {\n        _6131 = L.sheen_scale;\n    }\n    else\n    {\n        _6131 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6131);\n    vec3 _6144 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6155 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6164 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6144), 0.0);\n        float param_13 = _6164;\n        float param_14 = ndv;\n        result += ((L.sheen * _6155) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6164)) * _6164) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6144;\n        float param_18 = max(dot(v, _6144), 0.0);\n        result += (_6155 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4146 = tdh / at;\n    float _4150 = bdh / ab;\n    float _4162 = ((_4146 * _4146) + (_4150 * _4150)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4162) * _4162);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4342 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4421 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4421) * _4421);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4342);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4342));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3552 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3555 = _3552.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3555 * _3555, exp2((-9.27999973297119140625) * ndv)) * _3555) + _3552.y)) + _3552.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3406 = rough * rough;\n    float _3436 = 0.60000002384185791015625 * _3406;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3406)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3436, 0.0500000007450580596923828125 + _3436, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3406 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4029;\n        if (L.aniso >= 0.0)\n        {\n            _4029 = L.b;\n        }\n        else\n        {\n            _4029 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4029, v), _4029), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4062 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4062.x) + (vec3(L.f90) * _4062.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4117 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4117.x) + _4117.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3594 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3594.x) + vec3(_3594.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _4819 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _4823 = fa_xm_origin(param_1);\n    vec2 _4829 = (uv * _4819) - vec2(0.5);\n    vec2 _4832 = fract(_4829);\n    vec2 _4835 = floor(_4829);\n    vec2 param_2 = _4819;\n    vec2 param_3 = _4823;\n    vec2 param_4 = _4835;\n    vec2 param_5 = _4819;\n    vec2 param_6 = _4823;\n    vec2 param_7 = _4835 + vec2(1.0, 0.0);\n    vec2 param_8 = _4819;\n    vec2 param_9 = _4823;\n    vec2 param_10 = _4835 + vec2(0.0, 1.0);\n    vec2 param_11 = _4819;\n    vec2 param_12 = _4823;\n    vec2 param_13 = _4835 + vec2(1.0);\n    vec3 _4877 = vec3(_4832.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4877), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4877), vec3(_4832.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _4896 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _4900 = clamp(lod, 0.0, _4896);\n    int _4904 = int(floor(_4900));\n    int param = _4904;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _4914 = float(_4904);\n    float _4915 = _4900 - _4914;\n    bool _4917 = _4915 > 0.001000000047497451305389404296875;\n    bool _4924;\n    if (_4917)\n    {\n        _4924 = _4914 < _4896;\n    }\n    else\n    {\n        _4924 = _4917;\n    }\n    if (_4924)\n    {\n        int param_2 = _4904 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_4915));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4950 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _4950.x) + (vec3(f90) * _4950.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _4978 = max(s.thickness, 0.0);\n    bool _4983 = _4978 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _4983)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _4978);\n    }\n    bool _5008 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5015;\n    if (!_5008)\n    {\n        _5015 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5015 = _5008;\n    }\n    if (_5015)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_4983)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _4978);\n    }\n    vec4 _5050 = vec4(world, 1.0);\n    float _5055 = dot(fa_mesh_fs_params[28], _5050);\n    vec2 uv = vec2(0.5);\n    if (_5055 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5073 = vec2(dot(fa_mesh_fs_params[26], _5050), dot(fa_mesh_fs_params[27], _5050)) / vec2(_5055);\n        float _5081;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5081 = (_5073.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5081 = 0.5 - (_5073.y * 0.5);\n        }\n        uv = vec2((_5073.x * 0.5) + 0.5, _5081);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3200 = int(fa_shadows[25].x + 0.5);\n    float _3210 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3215 = _3200 > 0;\n    bool _3224;\n    if (_3215)\n    {\n        int param = _3200 - 1;\n        _3224 = _3210 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3224 = _3215;\n    }\n    if (_3224)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3230 = _3200 > 1;\n        bool _3237;\n        if (_3230)\n        {\n            _3237 = _3210 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3237 = _3230;\n        }\n        if (_3237)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3243 = _3200 > 2;\n        bool _3250;\n        if (_3243)\n        {\n            _3250 = _3210 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3250 = _3243;\n        }\n        if (_3250)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3256 = _3200 > 3;\n        bool _3263;\n        if (_3256)\n        {\n            _3263 = _3210 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3263 = _3256;\n        }\n        if (_3263)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7338 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7338 = -_7338;\n    }\n    vec3 _6628 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7338, fa_world_tangent, fa_uv, fa_vertex_color, _6628, gl_FrontFacing);\n    Surface _6636 = fa_standard_surface(param_1);\n    vec3 _7369 = _6636.albedo;\n    float _7370 = _6636.alpha;\n    vec3 _7371 = _6636.normal;\n    float _7372 = _6636.metallic;\n    float _7373 = _6636.roughness;\n    float _7374 = _6636.occlusion;\n    vec3 _7375 = _6636.emission;\n    float _7376 = _6636.clearcoat;\n    float _7377 = _6636.clearcoat_roughness;\n    vec3 _7378 = _6636.sheen_color;\n    float _7379 = _6636.sheen_roughness;\n    float _7380 = _6636.anisotropy;\n    float _7381 = _6636.anisotropy_rotation;\n    float _7382 = _6636.specular;\n    float _7383 = _6636.ior;\n    vec3 _7384 = _6636.specular_color;\n    float _7385 = _6636.transmission;\n    float _7386 = _6636.thickness;\n    vec3 _7387 = _6636.attenuation_color;\n    float _7388 = _6636.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7338, fa_world_tangent, fa_uv, fa_vertex_color, _6628, gl_FrontFacing);\n    Surface param_3 = _6636;\n    surface(param_2, param_3);\n    _7369 = param_3.albedo;\n    _7370 = param_3.alpha;\n    _7371 = param_3.normal;\n    _7372 = param_3.metallic;\n    _7373 = param_3.roughness;\n    _7374 = param_3.occlusion;\n    _7375 = param_3.emission;\n    _7376 = param_3.clearcoat;\n    _7377 = param_3.clearcoat_roughness;\n    _7378 = param_3.sheen_color;\n    _7379 = param_3.sheen_roughness;\n    _7380 = param_3.anisotropy;\n    _7381 = param_3.anisotropy_rotation;\n    _7382 = param_3.specular;\n    _7383 = param_3.ior;\n    _7384 = param_3.specular_color;\n    _7385 = param_3.transmission;\n    _7386 = param_3.thickness;\n    _7387 = param_3.attenuation_color;\n    _7388 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7338;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7369 = param_6;\n    _7371 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7369;\n    }\n    else\n    {\n        vec3 _6676 = normalize(_7371);\n        float _6683 = clamp(_7372, 0.0, 1.0);\n        float _6687 = clamp(_7373, 0.0500000007450580596923828125, 1.0);\n        float _6691 = _6687 * _6687;\n        float _6695 = _6691 * _6691;\n        float _6700 = max(dot(_6676, _6628), 9.9999997473787516355514526367188e-05);\n        float _6706 = 1.0 - _6683;\n        float _6707 = clamp(_7385, 0.0, 1.0) * _6706;\n        vec3 _6716 = (_7369 * _6706) * (1.0 - _6707);\n        vec3 _6723 = mix(vec3(0.039999999105930328369140625), _7369, vec3(_6683));\n        vec3 f0 = _6723;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7338, fa_world_tangent, fa_uv, fa_vertex_color, _6628, gl_FrontFacing);\n        Surface param_9 = Surface(_7369, _7370, _7371, _7372, _7373, _7374, _7375, _7376, _7377, _7378, _7379, _7380, _7381, _7382, _7383, _7384, _7385, _7386, _7387, _7388);\n        vec3 param_10 = _6676;\n        vec3 param_11 = _6628;\n        float param_12 = _6683;\n        float param_13 = _6687;\n        vec3 param_14 = _6723;\n        FaLayers _6739 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6676;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6716) * _7374;\n        if (_6739.on)\n        {\n            lit *= _6739.base_scale;\n        }\n        int _6761 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6761; ln++)\n        {\n            int param_16 = ln;\n            int _6774 = fa_cl_light(param_16);\n            bool _6777 = fa_lm.z > 0.5;\n            bool _6783;\n            if (_6777)\n            {\n                int param_17 = _6774;\n                _6783 = fa_light_baked(param_17);\n            }\n            else\n            {\n                _6783 = _6777;\n            }\n            if (_6783)\n            {\n                continue;\n            }\n            int param_18 = _6774;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7338;\n            LightSample _6795 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6803 = max(dot(_6676, _6795.direction), 0.0);\n            float _6809 = _6795.attenuation * _6795.shadow;\n            vec3 _6814 = normalize(_6795.direction + _6628);\n            float _6819 = max(dot(_6676, _6814), 0.0);\n            float _6824 = max(dot(_6628, _6814), 0.0);\n            bool _6831;\n            if (fa_light_is_area)\n            {\n                _6831 = !_6739.on;\n            }\n            else\n            {\n                _6831 = fa_light_is_area;\n            }\n            if (_6831)\n            {\n                int param_21 = _6774;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6676;\n                vec3 param_24 = _6628;\n                vec3 param_25 = _6716;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6687;\n                float param_29 = _6700;\n                float param_30 = _6809;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6739;\n                    int param_32 = _6774;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6676;\n                    vec3 param_35 = _6628;\n                    vec3 param_36 = _6795.direction;\n                    vec3 param_37 = _6716;\n                    vec3 param_38 = f0;\n                    float param_39 = _6687;\n                    float param_40 = _6700;\n                    float param_41 = _6809;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6739.on)\n                    {\n                        FaLayers param_42 = _6739;\n                        vec3 param_43 = _6716;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6676;\n                        vec3 param_46 = _6628;\n                        vec3 param_47 = _6795.direction;\n                        vec3 param_48 = _6814;\n                        float param_49 = _6803;\n                        float param_50 = _6700;\n                        float param_51 = _6819;\n                        float param_52 = _6824;\n                        float param_53 = _6691;\n                        float param_54 = _6695;\n                        int param_55 = _6774;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6809));\n                    }\n                    else\n                    {\n                        float _6937 = ((_6819 * _6819) * (_6695 - 1.0)) + 1.0;\n                        int param_56 = _6774;\n                        lit += (((_6716 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6824, 5.0))) * (((_6695 / ((3.1415927410125732421875 * _6937) * _6937)) * (0.5 / max(mix((2.0 * _6803) * _6700, _6803 + _6700, _6691), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6803))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6803 * _6809));\n                    }\n                }\n            }\n        }\n        if (_6739.on)\n        {\n            FaLayers param_57 = _6739;\n            vec3 param_58 = _6676;\n            vec3 param_59 = _6628;\n            vec3 param_60 = f0;\n            float param_61 = _6687;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7374);\n        }\n        else\n        {\n            vec3 param_62 = _6676;\n            vec3 param_63 = _6628;\n            vec3 param_64 = f0;\n            float param_65 = _6687;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7374);\n        }\n        if (_6707 > 0.0)\n        {\n            float _7035;\n            if (_6739.on)\n            {\n                _7035 = _6739.f90;\n            }\n            else\n            {\n                _7035 = 1.0;\n            }\n            float _7043;\n            if (_6739.on)\n            {\n                _7043 = _6739.base_scale;\n            }\n            else\n            {\n                _7043 = 1.0;\n            }\n            Surface param_66 = Surface(_7369, _7370, _7371, _7372, _7373, _7374, _7375, _7376, _7377, _7378, _7379, _7380, _7381, _7382, _7383, _7384, _7385, _7386, _7387, _7388);\n            vec3 param_67 = _6676;\n            vec3 param_68 = _6628;\n            float param_69 = _6687;\n            vec3 param_70 = f0;\n            float param_71 = _7035;\n            float param_72 = _7043;\n            float param_73 = _6707;\n            float param_74 = fa_tr_blend;\n            vec3 _7067 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7067;\n        }\n        result = lit;\n    }\n    vec3 _7074 = result;\n    vec3 _7075 = _7074 + _7375;\n    result = _7075;\n    vec3 param_75 = _7075;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7084 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7091;\n    if (!_7084)\n    {\n        _7091 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7091 = _7084;\n    }\n    if (_7091)\n    {\n        vec3 _7100 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7106 = dot(_7100, fa_mesh_fs_params[9].xyz);\n        bool _7110 = fa_mesh_fs_params[9].w > 0.5;\n        float _7111;\n        if (_7110)\n        {\n            _7111 = _7106;\n        }\n        else\n        {\n            _7111 = length(_7100);\n        }\n        float _7123 = _7111 - fa_mesh_fs_params[8].x;\n        if (_7123 > 0.0)\n        {\n            float _7132 = fa_mesh_fs_params[7].w * _7123;\n            float tau = _7132 * _7132;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7148;\n                if (_7110)\n                {\n                    _7148 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7106);\n                }\n                else\n                {\n                    _7148 = fa_mesh_fs_params[0].y;\n                }\n                float _7169 = mix(_7148, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7111, 0.0, 1.0));\n                float _7173 = fa_world_pos.y - _7169;\n                float _7178 = _7169 - fa_mesh_fs_params[8].z;\n                float _7183 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7186 = _7178 <= 0.0;\n                bool _7187 = !_7186;\n                bool _7193;\n                if (_7187)\n                {\n                    _7193 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7193 = _7186;\n                }\n                float _7194;\n                if (_7193)\n                {\n                    _7194 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7194 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7178, 80.0));\n                }\n                bool _7221;\n                if (_7187)\n                {\n                    _7221 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7221 = _7186;\n                }\n                float _7222;\n                if (_7221)\n                {\n                    _7222 = fa_mesh_fs_params[8].y * _7178;\n                }\n                else\n                {\n                    _7222 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7178, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7247 = _7183 <= 0.0;\n                bool _7254;\n                if (!_7247)\n                {\n                    _7254 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7254 = _7247;\n                }\n                float _7255;\n                if (_7254)\n                {\n                    _7255 = fa_mesh_fs_params[8].y * _7183;\n                }\n                else\n                {\n                    _7255 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7183, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7282;\n                if (abs(_7173) < 0.001000000047497451305389404296875)\n                {\n                    _7282 = _7194;\n                }\n                else\n                {\n                    _7282 = (_7255 - _7222) / _7173;\n                }\n                tau += (_7123 * max(_7282, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _7318 = 1.0 - fa_tr_blend;\n        result /= vec3(_7318);\n        _7370 *= _7318;\n    }\n    fa_frag_color = vec4(result, _7370);\n}\n\n",
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
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_597",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
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
            "inst_name": "_2264",
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
            "inst_name": "_6233",
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
              "name": "fa_env_tex",
              "multisampled": false,
              "type": "cube",
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
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
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
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 11,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 9) in vec4 fa_inst_d0;\nlayout(location = 10) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _94 = cross(model[1].xyz, model[2].xyz);\n    float _100 = (dot(model[0].xyz, _94) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_94 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _100, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _100), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _190 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _197 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_190 * _197).z;\n    fa_pre_r0 = vec3(_190[0].x, _190[1].x, _190[2].x);\n    fa_pre_r1 = vec3(_190[0].y, _190[1].y, _190[2].y);\n    fa_pre_r2 = vec3(_190[0].z, _190[1].z, _190[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _197;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[32];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _815 = base_t;\n    _815.x = _264.x;\n    _815.y = _264.y;\n    _815.z = _264.z;\n    base_t = _815;\n    vec4 _280 = (_815 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _770 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _823 = _317;\n        _823.x = _322.x;\n        _823.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _823;\n        _770 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _826 = mrt;\n    _826.x = _351.x;\n    _826.y = _351.y;\n    _826.z = _351.z;\n    mrt = _826;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _775 = fa_mesh_fs_params[20].x;\n    float _776 = fa_mesh_fs_params[20].y;\n    float _779 = fa_mesh_fs_params[20].z;\n    float _778 = fa_mesh_fs_params[21].w;\n    float _781 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _775 *= _393.y;\n            _776 *= _393.z;\n            _778 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _779 *= mrt.x;\n            _781 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _770, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _775, _776, fa_mesh_fs_params[21].xyz, _778, _779, fa_mesh_fs_params[20].w, _781, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _665 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _665 = -_665;\n    }\n    vec3 _575 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _575, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _575, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _590 = normalize(param_2.normal);\n    vec3 _605 = normalize(vec3(dot(fa_pre_r0, _590), dot(fa_pre_r1, _590), dot(fa_pre_r2, _590)));\n    float _617 = _605.z;\n    vec2 e = _605.xy / vec2((abs(_605.x) + abs(_605.y)) + abs(_617));\n    if (_617 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 2) out vec3 fa_world_pos;\nlayout(location = 3) out vec3 fa_world_normal;\nlayout(location = 4) out vec4 fa_world_tangent;\nlayout(location = 5) out vec2 fa_uv;\nlayout(location = 6) out vec4 fa_vertex_color;\nlayout(location = 7) out float fa_pre_depth;\nlayout(location = 8) out vec3 fa_pre_r0;\nlayout(location = 9) out vec3 fa_pre_r1;\nlayout(location = 10) out vec3 fa_pre_r2;\nlayout(location = 11) in vec4 fa_inst_d0;\nlayout(location = 12) in vec4 fa_inst_d1;\nlayout(location = 0) flat out vec4 fa_inst_v0;\nlayout(location = 1) flat out vec4 fa_inst_v1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_begin()\n{\n    vec4 param = fa_inst_d0;\n    vec4 param_1 = fa_inst_d1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n    fa_inst_v0 = fa_inst_d0;\n    fa_inst_v1 = fa_inst_d1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _196 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_196 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_196 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_196 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _99 = cross(model[1].xyz, model[2].xyz);\n    float _105 = (dot(model[0].xyz, _99) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_99 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _105, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _105), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.world_pos.y += raise;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _303 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _310 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_303 * _310).z;\n    fa_pre_r0 = vec3(_303[0].x, _303[1].x, _303[2].x);\n    fa_pre_r1 = vec3(_303[0].y, _303[1].y, _303[2].y);\n    fa_pre_r2 = vec3(_303[0].z, _303[1].z, _303[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _310;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[32];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _264 = fa_tex_fix(param_2, param_3);\n    vec4 _815 = base_t;\n    _815.x = _264.x;\n    _815.y = _264.y;\n    _815.z = _264.z;\n    base_t = _815;\n    vec4 _280 = (_815 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _770 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _313 = fa_tex_fix(param_6, param_7);\n        vec3 _317 = (_313 * 2.0) - vec3(1.0);\n        vec2 _322 = _317.xy * fa_mesh_fs_params[6].x;\n        vec3 _823 = _317;\n        _823.x = _322.x;\n        _823.y = _322.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _823;\n        _770 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _351 = fa_tex_fix(param_12, param_13);\n    vec4 _826 = mrt;\n    _826.x = _351.x;\n    _826.y = _351.y;\n    _826.z = _351.z;\n    mrt = _826;\n    vec4 _381 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _381.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _393 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _423 = fa_tex_fix(param_20, param_21);\n    float _775 = fa_mesh_fs_params[20].x;\n    float _776 = fa_mesh_fs_params[20].y;\n    float _779 = fa_mesh_fs_params[20].z;\n    float _778 = fa_mesh_fs_params[21].w;\n    float _781 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _775 *= _393.y;\n            _776 *= _393.z;\n            _778 *= _381.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _779 *= mrt.x;\n            _781 *= mrt.w;\n        }\n    }\n    return Surface(_280.xyz, _280.w, _770, clamp(fa_mesh_fs_params[5].x * _351.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _351.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_393.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _423), _775, _776, fa_mesh_fs_params[21].xyz, _778, _779, fa_mesh_fs_params[20].w, _781, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _665 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _665 = -_665;\n    }\n    vec3 _575 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _575, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _665, fa_world_tangent, fa_uv, fa_vertex_color, _575, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _590 = normalize(param_2.normal);\n    vec3 _605 = normalize(vec3(dot(fa_pre_r0, _590), dot(fa_pre_r1, _590), dot(fa_pre_r2, _590)));\n    float _617 = _605.z;\n    vec2 e = _605.xy / vec2((abs(_605.x) + abs(_605.y)) + abs(_617));\n    if (_617 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 512,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_253",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 32,
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
