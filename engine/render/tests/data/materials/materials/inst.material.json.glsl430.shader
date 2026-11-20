{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "250346cb320d68211881ea973a1fc30cb1589affe0eed76e8a4d3e3d69287371",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3663[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[39];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1504 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1511;\n    if (!_1504)\n    {\n        _1511 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1511 = _1504;\n    }\n    bool _1519;\n    if (!_1511)\n    {\n        _1519 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1519 = _1511;\n    }\n    bool _1526;\n    if (!_1519)\n    {\n        _1526 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1526 = _1519;\n    }\n    bool _1533;\n    if (!_1526)\n    {\n        _1533 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1533 = _1526;\n    }\n    if (_1533)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1543 = vec4(world_pos, 1.0);\n    float _1549 = dot(fa_mesh_fs_params[16], _1543);\n    if (!(_1549 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1571 = vec2(dot(fa_mesh_fs_params[14], _1543), dot(fa_mesh_fs_params[15], _1543)) / vec2(_1549);\n    int _1575 = int(fa_mesh_fs_params[18].x);\n    int _1579 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1579) + clamp(int(floor(((_1571.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1579 - 1)) * _1575)) + clamp(int(floor(((_1571.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1575 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1655 = fa_cluster_texel(param);\n    return ivec2(int(_1655.x), int(_1655.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4761 = fa_cluster_lookup(param);\n    fa_cl_slot = _4761.x;\n    fa_cl_local = _4761.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5920 = fa_linear_to_srgb(param);\n        c = _5920;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5928 = fa_srgb_to_linear(param_1);\n            c = _5928;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _448;\n    if (i.front_facing)\n    {\n        _448 = i.world_normal;\n    }\n    else\n    {\n        _448 = -i.world_normal;\n    }\n    vec3 _472 = normalize(i.world_tangent.xyz - (_448 * dot(_448, i.world_tangent.xyz)));\n    vec3 _499 = normalize(((_472 * m.x) + ((cross(_448, _472) * i.world_tangent.w) * m.y)) + (_448 * m.z));\n    vec3 _502;\n    if (i.front_facing)\n    {\n        _502 = _499;\n    }\n    else\n    {\n        _502 = -_499;\n    }\n    return _502;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5959 = fa_tex_fix(param_2, param_3);\n    vec4 _7419 = base_t;\n    _7419.x = _5959.x;\n    _7419.y = _5959.y;\n    _7419.z = _5959.z;\n    base_t = _7419;\n    vec4 _5973 = (_7419 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7244 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6005 = fa_tex_fix(param_6, param_7);\n        vec3 _6008 = (_6005 * 2.0) - vec3(1.0);\n        vec2 _6013 = _6008.xy * fa_mesh_fs_params[6].x;\n        vec3 _7427 = _6008;\n        _7427.x = _6013.x;\n        _7427.y = _6013.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7427;\n        _7244 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6041 = fa_tex_fix(param_12, param_13);\n    vec4 _7430 = mrt;\n    _7430.x = _6041.x;\n    _7430.y = _6041.y;\n    _7430.z = _6041.z;\n    mrt = _7430;\n    vec4 _6069 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6069.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6080 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6110 = fa_tex_fix(param_20, param_21);\n    float _7249 = fa_mesh_fs_params[20].x;\n    float _7250 = fa_mesh_fs_params[20].y;\n    float _7253 = fa_mesh_fs_params[20].z;\n    float _7252 = fa_mesh_fs_params[21].w;\n    float _7255 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7249 *= _6080.y;\n            _7250 *= _6080.z;\n            _7252 *= _6069.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7253 *= mrt.x;\n            _7255 *= mrt.w;\n        }\n    }\n    return Surface(_5973.xyz, _5973.w, _7244, clamp(fa_mesh_fs_params[5].x * _6041.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6041.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6080.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6110), _7249, _7250, fa_mesh_fs_params[21].xyz, _7252, _7253, fa_mesh_fs_params[20].w, _7255, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1735 = rect.zw - rect.xy;\n    vec2 _1739 = _1735 * atlas;\n    vec2 _1743 = ddx * _1739;\n    vec2 _1747 = ddy * _1739;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1735), clamp(0.5 * log2(max(max(dot(_1743, _1743), dot(_1747, _1747)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1780 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1787;\n    if (!_1780)\n    {\n        _1787 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1787 = _1780;\n    }\n    if (_1787)\n    {\n        return;\n    }\n    vec3 _1793 = dFdx(world_pos);\n    vec3 _1796 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1800 = fa_cluster_texel(param);\n    int _1804 = int(_1800.w);\n    if (_1804 < 1)\n    {\n        return;\n    }\n    int _1814 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1814;\n    vec4 _1818 = fa_light_texel(param_1);\n    vec2 _1821 = _1818.yz;\n    int _1825 = int(_1818.w);\n    int param_2 = _1814 + 1;\n    vec4 _1830 = fa_light_texel(param_2);\n    float _1831 = _1830.x;\n    int _1837 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1841 = int(_1800.z);\n    vec3 _2106;\n    for (int k = 0; k < _1804; k++)\n    {\n        int _1854 = _1841 + k;\n        int param_3 = _1825 + (_1854 >> 2);\n        int _1871 = (_1814 + 2) + (int(fa_light_texel(param_3)[_1854 & 3]) * 7);\n        int param_4 = _1871 + 6;\n        vec4 _1876 = fa_light_texel(param_4);\n        if (((int(_1876.w + 0.5) >> _1837) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1871;\n        vec4 _1891 = fa_light_texel(param_5);\n        int param_6 = _1871 + 1;\n        vec4 _1896 = fa_light_texel(param_6);\n        int param_7 = _1871 + 2;\n        vec4 _1901 = fa_light_texel(param_7);\n        vec3 _1904 = _1891.xyz;\n        float _1909 = dot(_1904, world_pos) + _1891.w;\n        vec3 _1911 = _1896.xyz;\n        float _1916 = dot(_1911, world_pos) + _1896.w;\n        vec3 _1918 = _1901.xyz;\n        float _1923 = dot(_1918, world_pos) + _1901.w;\n        bool _1928 = abs(_1909) > 0.5;\n        bool _1936;\n        if (!_1928)\n        {\n            _1936 = abs(_1916) > 0.5;\n        }\n        else\n        {\n            _1936 = _1928;\n        }\n        bool _1944;\n        if (!_1936)\n        {\n            _1944 = abs(_1923) > 0.5;\n        }\n        else\n        {\n            _1944 = _1936;\n        }\n        if (_1944)\n        {\n            continue;\n        }\n        float _1959 = clamp(dot(geo_normal, normalize(_1918)) * _1876.z, 0.0, 1.0);\n        if (_1959 <= 0.0)\n        {\n            continue;\n        }\n        float _1979 = (clamp((0.5 - abs(_1923)) * 10.0, 0.0, 1.0) * _1959) * _1876.x;\n        vec2 _1987 = vec2(_1909 + 0.5, 0.5 - _1916);\n        vec2 _1997 = vec2(dot(_1904, _1793), dot(_1911, _1793));\n        vec2 _2007 = vec2(dot(_1904, _1796), dot(_1911, _1796));\n        int param_8 = _1871 + 5;\n        vec4 _2012 = fa_light_texel(param_8);\n        int param_9 = _1871 + 3;\n        vec4 _2017 = fa_light_texel(param_9);\n        int param_10 = _1871 + 4;\n        vec4 _2022 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2012.xyz;\n        bool _2032 = _2017.z > _2017.x;\n        if (_2032)\n        {\n            vec4 param_11 = _2017;\n            vec2 param_12 = _1987;\n            vec2 param_13 = _1821;\n            vec2 param_14 = _1997;\n            vec2 param_15 = _2007;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1831 > 0.5) && (_1831 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2058 = fa_dc_to_linear(param_16);\n                vec4 _7324 = tx;\n                _7324.x = _2058.x;\n                _7324.y = _2058.y;\n                _7324.z = _2058.z;\n                tx = _7324;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1979 * tex_a) * _2012.w, 0.0, 1.0)));\n        if (_2022.z > _2022.x)\n        {\n            vec4 param_17 = _2022;\n            vec2 param_18 = _1987;\n            vec2 param_19 = _1821;\n            vec2 param_20 = _1997;\n            vec2 param_21 = _2007;\n            vec4 _2102 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1831 > 1.5)\n            {\n                vec3 param_22 = _2102.xyz;\n                vec3 _2112 = fa_dc_to_srgb(param_22);\n                _2106 = _2112;\n            }\n            else\n            {\n                _2106 = _2102.xyz;\n            }\n            vec3 _2121 = (_2106 * 2.0) - vec3(1.0);\n            vec2 _2126 = _2121.xy * _1876.y;\n            vec3 _2148 = (normalize(_1904) * _2126.x) + (normalize(_1911) * _2126.y);\n            vec3 _2151 = normalize(normal);\n            normal = normalize(mix(_2151, normalize((_2151 * max(_2121.z, 0.0500000007450580596923828125)) + (_2148 - (_2151 * dot(_2151, _2148)))), vec3(clamp(_1979 * (_2032 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3589 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3596 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3599 = int(_3589);\n    int _3602 = int(_3596);\n    float _3612 = _3596 - float(_3602);\n    int _3667 = (_3599 * 9) + _3602;\n    int _3687 = ((_3599 + 1) * 9) + _3602;\n    return mix(mix(_3663[_3667], _3663[_3667 + 1], _3612), mix(_3663[_3687], _3663[_3687 + 1], _3612), _3589 - float(_3599));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7167 = false;\n    float _7168 = 1.0;\n    float _7169 = 1.0;\n    float _7170 = 1.0;\n    float _7171 = 0.0;\n    float _7172 = 0.0;\n    float _7173 = 0.0;\n    float _7174 = 0.0;\n    float _7176 = 1.0;\n    bool _7177 = false;\n    vec3 _7178 = vec3(0.0);\n    float _7179 = 1.0;\n    float _7180 = 1.0;\n    float _7181 = 1.0;\n    float _7182 = 0.0;\n    float _7183 = 0.0;\n    vec3 _7184 = vec3(1.0, 0.0, 0.0);\n    vec3 _7185 = vec3(0.0, 0.0, 1.0);\n    float _7186 = 1.0;\n    float _7187 = 1.0;\n    float _3738 = clamp(s.specular, 0.0, 1.0);\n    float _3742 = clamp(s.ior, 1.0, 3.0);\n    bool _3747 = (_3738 != 1.0) || (_3742 != 1.5);\n    bool _3756;\n    if (!_3747)\n    {\n        _3756 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3756 = _3747;\n    }\n    if (_3756)\n    {\n        float _3764 = (_3742 - 1.0) / (_3742 + 1.0);\n        f0 = mix(min(vec3(_3764 * _3764) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3738, s.albedo, vec3(metallic));\n        _7168 = mix(_3738, 1.0, metallic);\n        _7167 = true;\n    }\n    float _3791 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3791 > 0.0)\n    {\n        float _3799 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7171 = _3791;\n        _7172 = _3799;\n        float _3806 = _3799 * _3799;\n        _7173 = _3806;\n        _7174 = _3806 * _3806;\n        float _3818 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7176 = _3818;\n        _7169 = 1.0 - (_3791 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3818, 0.0, 1.0), 5.0))));\n        _7167 = true;\n    }\n    vec3 _3837 = max(s.sheen_color, vec3(0.0));\n    float _3846 = max(_3837.x, max(_3837.y, _3837.z));\n    if (_3846 > 0.0)\n    {\n        float _3854 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7177 = true;\n        _7178 = _3837;\n        _7179 = _3854;\n        _7180 = _3854 * _3854;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3854;\n        float _3871 = fa_sheen_albedo(param, param_1);\n        _7182 = _3871;\n        _7181 = 1.0 - min(_3846 * _3871, 1.0);\n        _7167 = true;\n    }\n    _7170 = _7169 * _7181;\n    float _3890 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3890 != 0.0)\n    {\n        vec3 _3905 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3905;\n        if (dot(_3905, _3905) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3917 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3917.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3917.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3917.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3921 = t;\n        vec3 _3922 = normalize(_3921);\n        t = _3922;\n        vec3 _3947 = normalize((_3922 * cos(s.anisotropy_rotation)) + ((cross(n, _3922) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7184 = _3947;\n        _7185 = cross(n, _3947);\n        float _3957 = roughness * roughness;\n        float _3963 = mix(_3957, 1.0, _3890 * _3890);\n        bool _3965 = _3890 > 0.0;\n        _7186 = _3965 ? _3963 : _3957;\n        _7187 = _3965 ? _3957 : _3963;\n        _7183 = _3890;\n        _7167 = true;\n    }\n    return FaLayers(_7167, _7168, _7169, _7170, _7171, _7172, _7173, _7174, i.world_normal, _7176, _7177, _7178, _7179, _7180, _7181, _7182, _7183, _7184, _7185, _7186, _7187);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3346 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3346;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4731;\n    if (fa_lm.z > 0.5)\n    {\n        _4731 = 0.0;\n    }\n    else\n    {\n        _4731 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _4742 = _4731 < 1.0;\n    bool _4748;\n    if (_4742)\n    {\n        int param = li;\n        _4748 = fa_light_baked(param);\n    }\n    else\n    {\n        _4748 = _4742;\n    }\n    return _4748 ? _4731 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _753 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _766 = (c - (ru * hx)) - p;\n        vec3 _772 = ru * (2.0 * hx);\n        float _778 = max(dot(_772, _772), 9.9999999392252902907785028219223e-09);\n        float _782 = dot(_766, _772);\n        float t = clamp((-_782) / _778, 0.0, 1.0);\n        if (_753)\n        {\n            float _797 = dot(r, _772);\n            float _803 = _778 - (_797 * _797);\n            if (abs(_803) > (9.9999997473787516355514526367188e-06 * _778))\n            {\n                t = clamp(((dot(r, _766) * _797) - _782) / _803, 0.0, 1.0);\n            }\n        }\n        return (p + _766) + (_772 * t);\n    }\n    vec3 q = p;\n    float _835 = dot(r, axis);\n    bool _843;\n    if (_753)\n    {\n        _843 = abs(_835) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _843 = _753;\n    }\n    if (_843)\n    {\n        float _853 = dot(c - p, axis) / _835;\n        if (_853 > 0.0)\n        {\n            q = p + (r * _853);\n        }\n    }\n    vec3 _866 = q - c;\n    vec2 xy = vec2(dot(_866, ru), dot(_866, uu));\n    if (shape > 0.5)\n    {\n        float _881 = length(xy);\n        if (_881 > hx)\n        {\n            xy *= (hx / _881);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _543;\n        if (_518 >= _514.z)\n        {\n            _543 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _543 = (d.z > 0.0) ? 4 : 5;\n        }\n        _528 = _543;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _673 = dot(d, right);\n    float _677 = dot(d, up);\n    float _688;\n    if (((_673 * _673) + (_677 * _677)) > 1.0000000133514319600180897396058e-10)\n    {\n        _688 = atan(_677, _673) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _688 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_688 - floor(_688)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _919 = fa_light_base(param);\n    bool _923 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _919;\n    vec4 _927 = fa_light_texel(param_1);\n    int param_2 = _919 + 1;\n    vec4 _932 = fa_light_texel(param_2);\n    float _935 = _932.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _947 = _923 && (_935 > 2.5);\n    fa_light_is_area = _947;\n    bool _949 = _935 < 0.5;\n    vec3 l;\n    if (_949)\n    {\n        l = normalize(_927.xyz);\n        if (_923)\n        {\n            int param_3 = _919 + 6;\n            vec4 _963 = fa_light_texel(param_3);\n            if (_963.z > 0.5)\n            {\n                int param_4 = _919 + 4;\n                vec4 _973 = fa_light_texel(param_4);\n                int param_5 = _919 + 5;\n                vec4 _978 = fa_light_texel(param_5);\n                vec2 param_6 = _963.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _973.xyz) * _973.w, (-dot(world_pos, _978.xyz)) * _978.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1008 = _927.xyz;\n        vec3 _1010 = _1008 - world_pos;\n        vec3 to_light = _1010;\n        float _1013 = length(_1010);\n        float reach = _1013;\n        bool front = true;\n        if (_947)\n        {\n            int param_8 = _919 + 7;\n            reach = max(_1013 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _919 + 4;\n            vec4 _1037 = fa_light_texel(param_9);\n            int param_10 = _919 + 5;\n            vec4 _1042 = fa_light_texel(param_10);\n            int param_11 = _919 + 6;\n            vec4 _1047 = fa_light_texel(param_11);\n            float _1048 = _1047.w;\n            int param_12 = _919 + 2;\n            vec3 _1055 = normalize(fa_light_texel(param_12).xyz);\n            bool _1057 = _1048 > 1.5;\n            bool _1065;\n            if (!_1057)\n            {\n                _1065 = dot(_1055, to_light) < 0.0;\n            }\n            else\n            {\n                _1065 = _1057;\n            }\n            front = _1065;\n            vec3 r = vec3(0.0);\n            vec3 _1074 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1078 = dot(n, n) > 0.5;\n            bool _1086;\n            if (_1078)\n            {\n                _1086 = dot(_1074, _1074) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1086 = _1078;\n            }\n            if (_1086)\n            {\n                r = reflect(-normalize(_1074), normalize(n));\n            }\n            vec3 param_13 = _1008;\n            vec3 param_14 = _1055;\n            vec3 param_15 = _1037.xyz;\n            vec3 param_16 = _1042.xyz;\n            float param_17 = _1037.w;\n            float param_18 = _1042.w;\n            float param_19 = _1048;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1122 = length(to_light);\n        dist = _1122;\n        l = to_light / vec3(max(_1122, 9.9999997473787516355514526367188e-05));\n        float _1136 = reach / max(_927.w, 0.001000000047497451305389404296875);\n        float _1142 = clamp(1.0 - (_1136 * _1136), 0.0, 1.0);\n        float _1144;\n        if (front)\n        {\n            _1144 = _1142 * _1142;\n        }\n        else\n        {\n            _1144 = 0.0;\n        }\n        atten = _1144;\n        bool _1155 = _935 < 2.5;\n        if ((_935 > 1.5) && _1155)\n        {\n            int param_22 = _919 + 2;\n            vec4 _1163 = fa_light_texel(param_22);\n            float _1173 = _1163.w;\n            int param_23 = _919 + 3;\n            vec4 _1178 = fa_light_texel(param_23);\n            float _1179 = _1178.x;\n            float cos_inner = _1179;\n            if (_1179 > 1.5)\n            {\n                cos_inner = mix(_1173, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1173, cos_inner, dot(-l, normalize(_1163.xyz)));\n        }\n        if (_923 && (_935 < 1.5))\n        {\n            int param_24 = _919 + 6;\n            vec4 _1203 = fa_light_texel(param_24);\n            if (_1203.z > 0.5)\n            {\n                vec3 _1211 = -to_light;\n                int param_25 = _919 + 4;\n                int param_26 = _919 + 5;\n                vec3 _1225 = fa_light_texel(param_25).xyz;\n                vec3 _1229 = fa_light_texel(param_26).xyz;\n                vec3 _1238 = vec3(dot(_1211, _1225), dot(_1211, _1229), dot(_1211, cross(_1225, _1229)));\n                vec3 param_27 = _1238;\n                int _1242 = fa_cube_face(param_27);\n                int param_28 = _1242;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1269 = vec2(dot(_1238, cross(param_29, param_30)), dot(_1238, param_30)) / vec2(max(dot(_1238, param_29), 9.9999997473787516355514526367188e-05));\n                int _1273 = _1242 / 3;\n                vec2 param_31 = _1203.xy + (vec2(float(_1242 - (_1273 * 3)), float(_1273)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1269.x), 0.5 - (0.5 * _1269.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _919 + 7;\n            vec4 _1303 = fa_light_texel(param_33);\n            if (_1303.z > 0.5)\n            {\n                int param_34 = _919 + 2;\n                int param_35 = _919 + 4;\n                int param_36 = _919 + 5;\n                vec2 param_37 = _1303.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_923 && _1155)\n            {\n                int param_42 = _919 + 6;\n                vec4 _1350 = fa_light_texel(param_42);\n                int param_43 = _919 + 7;\n                vec4 _1355 = fa_light_texel(param_43);\n                bool _1358 = _1350.z > 0.5;\n                bool _1365;\n                if (!_1358)\n                {\n                    _1365 = _1355.z > 0.5;\n                }\n                else\n                {\n                    _1365 = _1358;\n                }\n                if (_1365)\n                {\n                    int param_44 = _919 + 2;\n                    vec4 _1372 = fa_light_texel(param_44);\n                    vec3 _1376 = normalize(_1372.xyz);\n                    int param_45 = _919 + 4;\n                    vec4 _1381 = fa_light_texel(param_45);\n                    int param_46 = _919 + 5;\n                    vec4 _1386 = fa_light_texel(param_46);\n                    if (_1358)\n                    {\n                        vec3 _1394 = -to_light;\n                        float _1401 = _1372.w;\n                        float _1417 = 0.5 / max(dot(_1394, _1376) * (sqrt(max(1.0 - (_1401 * _1401), 0.0)) / max(_1401, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1350.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1394, _1381.xyz) * _1417), 0.5 - (dot(_1394, _1386.xyz) * _1417));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1355.z > 0.5)\n                    {\n                        vec2 param_49 = _1355.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1376;\n                        vec3 param_52 = _1381.xyz;\n                        vec3 param_53 = _1386.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7155 = _932.xyz * atten;\n    if (_923)\n    {\n        _7155 *= fa_light_tint;\n    }\n    int _1486;\n    if (_949)\n    {\n        _1486 = 0;\n    }\n    else\n    {\n        _1486 = ((_935 > 1.5) && (_935 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7155, atten, 1.0, dist, _1486);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2223;\n    if (i == 0)\n    {\n        _2223 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2239;\n        if (i == 1)\n        {\n            _2239 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2247;\n            if (i == 2)\n            {\n                _2247 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2247 = fa_shadows[24].w;\n            }\n            _2239 = _2247;\n        }\n        _2223 = _2239;\n    }\n    return _2223;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2280 = fa_shadow_depth(param, param_1);\n    float _2284;\n    if (conv.x < 0.5)\n    {\n        _2284 = _2280;\n    }\n    else\n    {\n        _2284 = (conv.y * conv.z) / (conv.z - (_2280 * (conv.z - conv.y)));\n    }\n    return _2284;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2211 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2211), sin(_2211)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2330 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2339;\n        if (k < 0.0)\n        {\n            _2339 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2339 = k;\n        }\n        float _2359 = clamp((_2339 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2330;\n            vec2 _2378 = fa_shadow_vogel(param_3, param_4, param_5) * _2359;\n            vec2 param_6 = uv + (_2378 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2390 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2390 < (zr - (length(_2378) * plane)))\n            {\n                sum += _2390;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2416 = sum / cnt;\n        float _2426;\n        if (k < 0.0)\n        {\n            _2426 = (-k) / max(_2416, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2426 = k;\n        }\n        radius = clamp(((max(zr - _2416, 0.0) * unit) * _2426) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2448 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2448; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2448;\n        float param_11 = _2330;\n        vec2 _2467 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2467 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2467) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2448);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2509 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2514 = clamp(dot(n, l), 0.0, 1.0);\n    float _2520 = sqrt(1.0 - (_2514 * _2514));\n    float _2527 = min(_2520 / max(_2514, 0.20000000298023223876953125), 4.0);\n    float _2532;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2532 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2532 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2557 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2532 * _2520)), 1.0);\n    float _2564 = _2557.x;\n    bool _2567 = _2564 < fa_shadows[ci * 1 + 16].x;\n    bool _2576;\n    if (!_2567)\n    {\n        _2576 = _2564 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2576 = _2567;\n    }\n    bool _2585;\n    if (!_2576)\n    {\n        _2585 = _2557.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2585 = _2576;\n    }\n    bool _2594;\n    if (!_2585)\n    {\n        _2594 = _2557.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2594 = _2585;\n    }\n    bool _2601;\n    if (!_2594)\n    {\n        _2601 = _2557.z > 1.0;\n    }\n    else\n    {\n        _2601 = _2594;\n    }\n    if (_2601)\n    {\n        return -1.0;\n    }\n    float _2609;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2609 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2609 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2557.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2557.z - ((_2609 * (1.0 + (0.5 * _2527))) / _2509);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2509;\n    float param_5 = _2509 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2527, 3.0)) * 0.5) / _2509;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2987 = int(fa_shadows[25].x + 0.5);\n    if (_2987 < 1)\n    {\n        return 1.0;\n    }\n    float _3002 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2987 - 1;\n    if (_3002 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3014 = _2987 > 1;\n    bool _3021;\n    if (_3014)\n    {\n        _3021 = _3002 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3021 = _3014;\n    }\n    if (_3021)\n    {\n        ci = 1;\n    }\n    bool _3025 = _2987 > 2;\n    bool _3032;\n    if (_3025)\n    {\n        _3032 = _3002 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3032 = _3025;\n    }\n    if (_3032)\n    {\n        ci = 2;\n    }\n    bool _3036 = _2987 > 3;\n    bool _3043;\n    if (_3036)\n    {\n        _3043 = _3002 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3043 = _3036;\n    }\n    if (_3043)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2987)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3069 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3069;\n        if (_3069 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3094;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3094 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3094 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3113 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3094, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3124 = clamp((_3002 - (fa_shadow_split_at(param_7) - _3113)) / _3113, 0.0, 1.0);\n        if (_3124 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2987)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3145 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3145;\n                if (_3145 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3124);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2667 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2674;\n    if (!_2667)\n    {\n        _2674 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2674 = _2667;\n    }\n    if (_2674)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2687 = fa_light_texel(param);\n    float _2688 = _2687.x;\n    if (_2688 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2697 = int(_2688 + 0.5);\n    int param_1 = _2697;\n    vec4 _2701 = fa_light_texel(param_1);\n    int param_2 = _2697 + 1;\n    vec4 _2706 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2709 = _2701.y;\n    if (_2709 > 0.0)\n    {\n        float _2726 = 1.0 - smoothstep(0.75 * _2709, _2709, length(world - fa_shadows[27].xyz));\n        fade = _2726;\n        if (_2726 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2701.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2750 = (_2697 + 2) + (face * 6);\n    int param_4 = _2750;\n    int param_5 = _2750 + 1;\n    int param_6 = _2750 + 3;\n    vec4 _2764 = fa_light_texel(param_6);\n    int param_7 = _2750 + 4;\n    vec4 _2769 = fa_light_texel(param_7);\n    int param_8 = _2750 + 5;\n    vec4 _2774 = fa_light_texel(param_8);\n    float _2786 = _2774.x * max(dot(_2764, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2791 = clamp(dot(n, l), 0.0, 1.0);\n    float _2814 = clamp(dot(n, _2764.xyz), -1.0, 1.0);\n    float _2833 = min(sqrt(1.0 - (_2814 * _2814)) / max(abs(dot(n, world - lpos)) / max(dot(_2764, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2836 = _2706.y;\n    float _2838;\n    if (_2836 > 0.0)\n    {\n        _2838 = _2836;\n    }\n    else\n    {\n        _2838 = 1.5 * _2786;\n    }\n    vec4 _2858 = vec4(world + (n * (_2838 * sqrt(1.0 - (_2791 * _2791)))), 1.0);\n    float _2862 = dot(_2764, _2858);\n    float _2865 = _2774.y;\n    if (_2862 < _2865)\n    {\n        return 1.0;\n    }\n    vec2 _2880 = vec2(dot(fa_light_texel(param_4), _2858), dot(fa_light_texel(param_5), _2858)) / vec2(_2862);\n    float _2882 = _2880.x;\n    bool _2885 = _2882 < _2769.x;\n    bool _2894;\n    if (!_2885)\n    {\n        _2894 = _2882 > _2769.z;\n    }\n    else\n    {\n        _2894 = _2885;\n    }\n    bool _2903;\n    if (!_2894)\n    {\n        _2903 = _2880.y < _2769.y;\n    }\n    else\n    {\n        _2903 = _2894;\n    }\n    bool _2912;\n    if (!_2903)\n    {\n        _2912 = _2880.y > _2769.w;\n    }\n    else\n    {\n        _2912 = _2903;\n    }\n    if (_2912)\n    {\n        return 1.0;\n    }\n    float _2918 = _2706.x;\n    float _2920;\n    if (_2918 > 0.0)\n    {\n        _2920 = _2918;\n    }\n    else\n    {\n        _2920 = 1.5 * _2786;\n    }\n    vec2 param_9 = _2880;\n    vec4 param_10 = _2769;\n    float param_11 = _2862 - (_2920 * (1.0 + (0.5 * _2833)));\n    float param_12 = _2786;\n    float param_13 = 1.0;\n    float param_14 = _2774.z * 0.25;\n    float param_15 = (_2786 * min(_2833, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2865, _2774.z);\n    int param_17 = int(_2701.z + 0.5);\n    float param_18 = _2701.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4475 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4482;\n    if (!_4475)\n    {\n        _4482 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4482 = _4475;\n    }\n    if (_4482)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4495 = fa_light_texel(param);\n    float _4496 = _4495.y;\n    float len = _4496;\n    if (_4496 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4508 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4518 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4508);\n    if (_4518 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4524 = len;\n    float _4527 = min(_4524, 0.89999997615814208984375 * dist);\n    len = _4527;\n    float _4532 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4508);\n    float _4537 = _4532 + (0.5 * _4527);\n    vec3 _4543 = world + (gn * _4532);\n    float _4545 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4609;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4560 = (float(k) + _4545) * 0.083333335816860198974609375;\n        vec3 _4568 = _4543 + (l * (_4560 * len));\n        vec4 _4574 = vec4(_4568, 1.0);\n        float _4580 = dot(fa_mesh_fs_params[28], _4574);\n        if (_4580 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4600 = vec2(dot(fa_mesh_fs_params[26], _4574), dot(fa_mesh_fs_params[27], _4574)) / vec2(_4580);\n        float _4604 = _4600.x * 0.5;\n        float _4605 = _4604 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4609 = (_4600.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4609 = 0.5 - (_4600.y * 0.5);\n        }\n        bool _4625 = _4605 < 0.0;\n        bool _4632;\n        if (!_4625)\n        {\n            _4632 = _4605 >= 1.0;\n        }\n        else\n        {\n            _4632 = _4625;\n        }\n        bool _4639;\n        if (!_4632)\n        {\n            _4639 = _4609 < 0.0;\n        }\n        else\n        {\n            _4639 = _4632;\n        }\n        bool _4646;\n        if (!_4639)\n        {\n            _4646 = _4609 >= 1.0;\n        }\n        else\n        {\n            _4646 = _4639;\n        }\n        if (_4646)\n        {\n            break;\n        }\n        vec4 _4665 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4605, _4609) * fa_mesh_fs_params[24].zw), 0);\n        if (_4665.w < 0.5)\n        {\n            continue;\n        }\n        float _4684 = (dot(fa_mesh_fs_params[29].xyz, _4568) + fa_mesh_fs_params[29].w) - _4665.x;\n        if ((_4684 > _4532) && (_4684 < _4537))\n        {\n            occ = max(occ, (1.0 - (_4560 * _4560)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4605, 0.5 - _4604), min(_4609, 1.0 - _4609))));\n        }\n    }\n    return 1.0 - (occ * _4518);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4787 = fa_baked_keep(param);\n    if (_4787 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4813 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7224 = _4813.color;\n    float _7225 = _4813.attenuation;\n    float _7226 = _4813.shadow;\n    bool _4816 = _4813.type == 0;\n    if (_4816 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4813.direction;\n        float _4827 = fa_shadow_factor(param_5, param_6);\n        _7226 = _4827;\n        _7224 *= _4827;\n    }\n    else\n    {\n        bool _4838 = _4813.type != 0;\n        bool _4844;\n        if (_4838)\n        {\n            _4844 = _7225 > 0.0;\n        }\n        else\n        {\n            _4844 = _4838;\n        }\n        if (_4844)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4813.direction;\n            float _4863 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7226 = _4863;\n            _7224 *= _4863;\n        }\n    }\n    bool _4873 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4879;\n    if (_4873)\n    {\n        _4879 = _7225 > 0.0;\n    }\n    else\n    {\n        _4879 = _4873;\n    }\n    if (_4879)\n    {\n        float _4886;\n        if (_4816)\n        {\n            _4886 = 1000000000.0;\n        }\n        else\n        {\n            _4886 = _4813._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4813.direction;\n        float param_18 = _4886;\n        float _4904 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7226 *= _4904;\n        _7224 *= _4904;\n    }\n    float _4917 = _7225;\n    float _4918 = _4917 * _4787;\n    _7225 = _4918;\n    return LightSample(_4813.direction, _7224, _4918, _7226, _4813._distance, _4813.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4952 = v - (n * dot(v, n));\n    vec3 t = _4952;\n    float _4956 = dot(_4952, _4952);\n    float l2 = _4956;\n    if (_4956 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4966;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4966 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4966 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4966;\n        l2 = dot(_4966, _4966);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5001 = dot(a, a);\n    float _5005 = dot(b, b);\n    if ((_5001 < 1.0000000195414813782625560981111e-24) || (_5005 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5019 = a * inversesqrt(_5001);\n    vec3 _5024 = b * inversesqrt(_5005);\n    float _5028 = dot(_5019, _5024);\n    float _5031 = abs(_5028);\n    float g = (((((((((((0.0416471660137176513671875 * _5031) - 0.1924748718738555908203125) * _5031) + 0.4179156124591827392578125) * _5031) - 0.616057217121124267578125) * _5031) + 0.777722418308258056640625) * _5031) - 0.999542415142059326171875) * _5031) + 1.570791721343994140625;\n    if (_5028 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5028 * _5028), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5019, _5024) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5088 = a.z > 0.0;\n    bool _5092 = b.z > 0.0;\n    if (_5088 && _5092)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5088 != _5092)\n        {\n            vec3 _5127 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5127.z = 0.0;\n            if (_5088)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5127;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5127;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5127;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5127;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5176 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5202 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5228 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5254 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5176;\n    vec3 param_1 = _5202;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5202;\n    vec3 param_7 = _5228;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5228;\n    vec3 param_13 = _5254;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5254;\n    vec3 param_19 = _5176;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5404 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5428 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5444 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5404;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5428;\n    vec4 param_9 = m;\n    vec3 param_10 = _5404;\n    vec3 param_11 = _5428;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5444;\n    vec4 param_14 = m;\n    vec3 param_15 = _5404;\n    vec3 param_16 = _5444;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5502 = fa_light_base(param);\n    int param_1 = _5502;\n    int param_2 = _5502 + 1;\n    int param_3 = _5502 + 2;\n    int param_4 = _5502 + 4;\n    vec4 _5524 = fa_light_texel(param_4);\n    int param_5 = _5502 + 5;\n    vec4 _5529 = fa_light_texel(param_5);\n    int param_6 = _5502 + 6;\n    vec4 _5534 = fa_light_texel(param_6);\n    float _5535 = _5534.w;\n    vec3 _5540 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5542 = _5535 < 1.5;\n    bool _5549;\n    if (_5542)\n    {\n        _5549 = dot(normalize(fa_light_texel(param_3).xyz), _5540) >= 0.0;\n    }\n    else\n    {\n        _5549 = _5542;\n    }\n    if (_5549)\n    {\n        return vec3(0.0);\n    }\n    bool _5558 = (_5535 > 0.5) && _5542;\n    float _5562 = _5558 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5565 = _5524.xyz;\n    float _5567 = _5524.w;\n    vec3 _5573 = _5529.xyz;\n    float _5575 = _5529.w;\n    vec3 up = _5573 * (_5575 * _5562);\n    float _5581;\n    if (_5558)\n    {\n        _5581 = (3.1415927410125732421875 * _5567) * _5567;\n    }\n    else\n    {\n        _5581 = (4.0 * _5567) * _5575;\n    }\n    if (_5535 > 1.5)\n    {\n        vec3 _5607 = cross(_5565, -_5540);\n        vec3 perp = _5607;\n        float _5611 = dot(_5607, _5607);\n        vec3 _5614;\n        if (_5611 > 1.0000000133514319600180897396058e-10)\n        {\n            _5614 = perp * inversesqrt(_5611);\n        }\n        else\n        {\n            _5614 = _5573;\n        }\n        perp = _5614;\n        up = _5614 * _5575;\n    }\n    float _5635 = max(_5581, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5645 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5645;\n    vec3 param_10 = n;\n    vec3 param_11 = _5540;\n    vec3 _5653 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5645;\n    vec3 param_13 = n;\n    vec3 param_14 = _5565 * (_5567 * _5562);\n    vec3 _5661 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5645;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5669 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5535;\n    vec3 param_20 = _5653;\n    vec3 param_21 = _5661;\n    vec3 param_22 = _5669;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5688 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5688;\n    vec2 param_26 = _5688 + vec2(64.0, 0.0);\n    vec4 _5698 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5535;\n    vec3 param_29 = _5653;\n    vec3 param_30 = _5661;\n    vec3 param_31 = _5669;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5698.x) + ((vec3(f90) - f0) * _5698.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5540, _5540)) + _5635) / _5635) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4212 = 1.0 / alpha;\n    return ((2.0 + _4212) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4212)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4247 = max(dot(L.nc, l), 0.0);\n    float _4253 = max(dot(L.nc, h), 0.0);\n    float _4262 = ((_4253 * _4253) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4262) * _4262)) * (0.5 / max(mix((2.0 * _4247) * L.coat_ndv, _4247 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4247)) * _4247;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5766;\n    if (L.sheen_on)\n    {\n        _5766 = L.sheen_scale;\n    }\n    else\n    {\n        _5766 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5766);\n    vec3 _5779 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5790 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5799 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5779), 0.0);\n        float param_13 = _5799;\n        float param_14 = ndv;\n        result += ((L.sheen * _5790) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5799)) * _5799) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5779;\n        float param_18 = max(dot(v, _5779), 0.0);\n        result += (_5790 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4115 = tdh / at;\n    float _4119 = bdh / ab;\n    float _4131 = ((_4115 * _4115) + (_4119 * _4119)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4131) * _4131);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4311 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4390 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4390) * _4390);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4311);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4311));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3521 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3524 = _3521.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3524 * _3524, exp2((-9.27999973297119140625) * ndv)) * _3524) + _3521.y)) + _3521.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3375 = rough * rough;\n    float _3405 = 0.60000002384185791015625 * _3375;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3375)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3405, 0.0500000007450580596923828125 + _3405, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3375 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3998;\n        if (L.aniso >= 0.0)\n        {\n            _3998 = L.b;\n        }\n        else\n        {\n            _3998 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3998, v), _3998), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4031 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4031.x) + (vec3(L.f90) * _4031.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4086 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4086.x) + _4086.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3563 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3563.x) + vec3(_3563.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3169 = int(fa_shadows[25].x + 0.5);\n    float _3179 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3184 = _3169 > 0;\n    bool _3193;\n    if (_3184)\n    {\n        int param = _3169 - 1;\n        _3193 = _3179 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3193 = _3184;\n    }\n    if (_3193)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3199 = _3169 > 1;\n        bool _3206;\n        if (_3199)\n        {\n            _3206 = _3179 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3206 = _3199;\n        }\n        if (_3206)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3212 = _3169 > 2;\n        bool _3219;\n        if (_3212)\n        {\n            _3219 = _3179 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3219 = _3212;\n        }\n        if (_3219)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3225 = _3169 > 3;\n        bool _3232;\n        if (_3225)\n        {\n            _3232 = _3179 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3232 = _3225;\n        }\n        if (_3232)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6924 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6924 = -_6924;\n    }\n    vec3 _6287 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6924, fa_world_tangent, fa_uv, fa_vertex_color, _6287, gl_FrontFacing);\n    Surface _6295 = fa_standard_surface(param_1);\n    vec3 _6955 = _6295.albedo;\n    float _6956 = _6295.alpha;\n    vec3 _6957 = _6295.normal;\n    float _6958 = _6295.metallic;\n    float _6959 = _6295.roughness;\n    float _6960 = _6295.occlusion;\n    vec3 _6961 = _6295.emission;\n    float _6962 = _6295.clearcoat;\n    float _6963 = _6295.clearcoat_roughness;\n    vec3 _6964 = _6295.sheen_color;\n    float _6965 = _6295.sheen_roughness;\n    float _6966 = _6295.anisotropy;\n    float _6967 = _6295.anisotropy_rotation;\n    float _6968 = _6295.specular;\n    float _6969 = _6295.ior;\n    vec3 _6970 = _6295.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6924, fa_world_tangent, fa_uv, fa_vertex_color, _6287, gl_FrontFacing);\n    Surface param_3 = _6295;\n    surface(param_2, param_3);\n    _6955 = param_3.albedo;\n    _6956 = param_3.alpha;\n    _6957 = param_3.normal;\n    _6958 = param_3.metallic;\n    _6959 = param_3.roughness;\n    _6960 = param_3.occlusion;\n    _6961 = param_3.emission;\n    _6962 = param_3.clearcoat;\n    _6963 = param_3.clearcoat_roughness;\n    _6964 = param_3.sheen_color;\n    _6965 = param_3.sheen_roughness;\n    _6966 = param_3.anisotropy;\n    _6967 = param_3.anisotropy_rotation;\n    _6968 = param_3.specular;\n    _6969 = param_3.ior;\n    _6970 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6924;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6955 = param_6;\n    _6957 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6955;\n    }\n    else\n    {\n        vec3 _6334 = normalize(_6957);\n        float _6341 = clamp(_6958, 0.0, 1.0);\n        float _6345 = clamp(_6959, 0.0500000007450580596923828125, 1.0);\n        float _6349 = _6345 * _6345;\n        float _6353 = _6349 * _6349;\n        float _6358 = max(dot(_6334, _6287), 9.9999997473787516355514526367188e-05);\n        vec3 _6364 = _6955 * (1.0 - _6341);\n        vec3 _6371 = mix(vec3(0.039999999105930328369140625), _6955, vec3(_6341));\n        vec3 f0 = _6371;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6924, fa_world_tangent, fa_uv, fa_vertex_color, _6287, gl_FrontFacing);\n        Surface param_9 = Surface(_6955, _6956, _6957, _6958, _6959, _6960, _6961, _6962, _6963, _6964, _6965, _6966, _6967, _6968, _6969, _6970);\n        vec3 param_10 = _6334;\n        vec3 param_11 = _6287;\n        float param_12 = _6341;\n        float param_13 = _6345;\n        vec3 param_14 = _6371;\n        FaLayers _6387 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6334;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6364) * _6960;\n        if (_6387.on)\n        {\n            lit *= _6387.base_scale;\n        }\n        int _6409 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6409; ln++)\n        {\n            int param_16 = ln;\n            int _6422 = fa_cl_light(param_16);\n            int param_17 = _6422;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _6422;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6924;\n            LightSample _6438 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6446 = max(dot(_6334, _6438.direction), 0.0);\n            float _6452 = _6438.attenuation * _6438.shadow;\n            vec3 _6457 = normalize(_6438.direction + _6287);\n            float _6462 = max(dot(_6334, _6457), 0.0);\n            float _6467 = max(dot(_6287, _6457), 0.0);\n            bool _6474;\n            if (fa_light_is_area)\n            {\n                _6474 = !_6387.on;\n            }\n            else\n            {\n                _6474 = fa_light_is_area;\n            }\n            if (_6474)\n            {\n                int param_21 = _6422;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6334;\n                vec3 param_24 = _6287;\n                vec3 param_25 = _6364;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6345;\n                float param_29 = _6358;\n                float param_30 = _6452;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6387;\n                    int param_32 = _6422;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6334;\n                    vec3 param_35 = _6287;\n                    vec3 param_36 = _6438.direction;\n                    vec3 param_37 = _6364;\n                    vec3 param_38 = f0;\n                    float param_39 = _6345;\n                    float param_40 = _6358;\n                    float param_41 = _6452;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6387.on)\n                    {\n                        FaLayers param_42 = _6387;\n                        vec3 param_43 = _6364;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6334;\n                        vec3 param_46 = _6287;\n                        vec3 param_47 = _6438.direction;\n                        vec3 param_48 = _6457;\n                        float param_49 = _6446;\n                        float param_50 = _6358;\n                        float param_51 = _6462;\n                        float param_52 = _6467;\n                        float param_53 = _6349;\n                        float param_54 = _6353;\n                        int param_55 = _6422;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6452));\n                    }\n                    else\n                    {\n                        float _6580 = ((_6462 * _6462) * (_6353 - 1.0)) + 1.0;\n                        int param_56 = _6422;\n                        lit += (((_6364 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6467, 5.0))) * (((_6353 / ((3.1415927410125732421875 * _6580) * _6580)) * (0.5 / max(mix((2.0 * _6446) * _6358, _6446 + _6358, _6349), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6446))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6446 * _6452));\n                    }\n                }\n            }\n        }\n        if (_6387.on)\n        {\n            FaLayers param_57 = _6387;\n            vec3 param_58 = _6334;\n            vec3 param_59 = _6287;\n            vec3 param_60 = f0;\n            float param_61 = _6345;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6960);\n        }\n        else\n        {\n            vec3 param_62 = _6334;\n            vec3 param_63 = _6287;\n            vec3 param_64 = f0;\n            float param_65 = _6345;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6960);\n        }\n        result = lit;\n    }\n    vec3 _6675 = result;\n    vec3 _6676 = _6675 + _6961;\n    result = _6676;\n    vec3 param_66 = _6676;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6685 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6692;\n    if (!_6685)\n    {\n        _6692 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6692 = _6685;\n    }\n    if (_6692)\n    {\n        vec3 _6701 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6707 = dot(_6701, fa_mesh_fs_params[9].xyz);\n        bool _6711 = fa_mesh_fs_params[9].w > 0.5;\n        float _6712;\n        if (_6711)\n        {\n            _6712 = _6707;\n        }\n        else\n        {\n            _6712 = length(_6701);\n        }\n        float _6724 = _6712 - fa_mesh_fs_params[8].x;\n        if (_6724 > 0.0)\n        {\n            float _6733 = fa_mesh_fs_params[7].w * _6724;\n            float tau = _6733 * _6733;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6749;\n                if (_6711)\n                {\n                    _6749 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6707);\n                }\n                else\n                {\n                    _6749 = fa_mesh_fs_params[0].y;\n                }\n                float _6770 = mix(_6749, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6712, 0.0, 1.0));\n                float _6774 = fa_world_pos.y - _6770;\n                float _6779 = _6770 - fa_mesh_fs_params[8].z;\n                float _6784 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6787 = _6779 <= 0.0;\n                bool _6788 = !_6787;\n                bool _6794;\n                if (_6788)\n                {\n                    _6794 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6794 = _6787;\n                }\n                float _6795;\n                if (_6794)\n                {\n                    _6795 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6795 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6779, 80.0));\n                }\n                bool _6822;\n                if (_6788)\n                {\n                    _6822 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6822 = _6787;\n                }\n                float _6823;\n                if (_6822)\n                {\n                    _6823 = fa_mesh_fs_params[8].y * _6779;\n                }\n                else\n                {\n                    _6823 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6779, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6848 = _6784 <= 0.0;\n                bool _6855;\n                if (!_6848)\n                {\n                    _6855 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6855 = _6848;\n                }\n                float _6856;\n                if (_6855)\n                {\n                    _6856 = fa_mesh_fs_params[8].y * _6784;\n                }\n                else\n                {\n                    _6856 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6784, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6883;\n                if (abs(_6774) < 0.001000000047497451305389404296875)\n                {\n                    _6883 = _6795;\n                }\n                else\n                {\n                    _6883 = (_6856 - _6823) / _6774;\n                }\n                tau += (_6724 * max(_6883, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6956);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_566",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
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
            "inst_name": "_2233",
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
            "inst_name": "_5868",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3663[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[39];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[1];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 7) in vec3 fa_lm;\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1504 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1511;\n    if (!_1504)\n    {\n        _1511 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1511 = _1504;\n    }\n    bool _1519;\n    if (!_1511)\n    {\n        _1519 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1519 = _1511;\n    }\n    bool _1526;\n    if (!_1519)\n    {\n        _1526 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1526 = _1519;\n    }\n    bool _1533;\n    if (!_1526)\n    {\n        _1533 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1533 = _1526;\n    }\n    if (_1533)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1543 = vec4(world_pos, 1.0);\n    float _1549 = dot(fa_mesh_fs_params[16], _1543);\n    if (!(_1549 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1571 = vec2(dot(fa_mesh_fs_params[14], _1543), dot(fa_mesh_fs_params[15], _1543)) / vec2(_1549);\n    int _1575 = int(fa_mesh_fs_params[18].x);\n    int _1579 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1579) + clamp(int(floor(((_1571.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1579 - 1)) * _1575)) + clamp(int(floor(((_1571.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1575 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1655 = fa_cluster_texel(param);\n    return ivec2(int(_1655.x), int(_1655.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4761 = fa_cluster_lookup(param);\n    fa_cl_slot = _4761.x;\n    fa_cl_local = _4761.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5920 = fa_linear_to_srgb(param);\n        c = _5920;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5928 = fa_srgb_to_linear(param_1);\n            c = _5928;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _448;\n    if (i.front_facing)\n    {\n        _448 = i.world_normal;\n    }\n    else\n    {\n        _448 = -i.world_normal;\n    }\n    vec3 _472 = normalize(i.world_tangent.xyz - (_448 * dot(_448, i.world_tangent.xyz)));\n    vec3 _499 = normalize(((_472 * m.x) + ((cross(_448, _472) * i.world_tangent.w) * m.y)) + (_448 * m.z));\n    vec3 _502;\n    if (i.front_facing)\n    {\n        _502 = _499;\n    }\n    else\n    {\n        _502 = -_499;\n    }\n    return _502;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5959 = fa_tex_fix(param_2, param_3);\n    vec4 _7419 = base_t;\n    _7419.x = _5959.x;\n    _7419.y = _5959.y;\n    _7419.z = _5959.z;\n    base_t = _7419;\n    vec4 _5973 = (_7419 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7244 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6005 = fa_tex_fix(param_6, param_7);\n        vec3 _6008 = (_6005 * 2.0) - vec3(1.0);\n        vec2 _6013 = _6008.xy * fa_mesh_fs_params[6].x;\n        vec3 _7427 = _6008;\n        _7427.x = _6013.x;\n        _7427.y = _6013.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7427;\n        _7244 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6041 = fa_tex_fix(param_12, param_13);\n    vec4 _7430 = mrt;\n    _7430.x = _6041.x;\n    _7430.y = _6041.y;\n    _7430.z = _6041.z;\n    mrt = _7430;\n    vec4 _6069 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6069.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6080 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6110 = fa_tex_fix(param_20, param_21);\n    float _7249 = fa_mesh_fs_params[20].x;\n    float _7250 = fa_mesh_fs_params[20].y;\n    float _7253 = fa_mesh_fs_params[20].z;\n    float _7252 = fa_mesh_fs_params[21].w;\n    float _7255 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7249 *= _6080.y;\n            _7250 *= _6080.z;\n            _7252 *= _6069.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7253 *= mrt.x;\n            _7255 *= mrt.w;\n        }\n    }\n    return Surface(_5973.xyz, _5973.w, _7244, clamp(fa_mesh_fs_params[5].x * _6041.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6041.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6080.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6110), _7249, _7250, fa_mesh_fs_params[21].xyz, _7252, _7253, fa_mesh_fs_params[20].w, _7255, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1735 = rect.zw - rect.xy;\n    vec2 _1739 = _1735 * atlas;\n    vec2 _1743 = ddx * _1739;\n    vec2 _1747 = ddy * _1739;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1735), clamp(0.5 * log2(max(max(dot(_1743, _1743), dot(_1747, _1747)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1780 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1787;\n    if (!_1780)\n    {\n        _1787 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1787 = _1780;\n    }\n    if (_1787)\n    {\n        return;\n    }\n    vec3 _1793 = dFdx(world_pos);\n    vec3 _1796 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1800 = fa_cluster_texel(param);\n    int _1804 = int(_1800.w);\n    if (_1804 < 1)\n    {\n        return;\n    }\n    int _1814 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1814;\n    vec4 _1818 = fa_light_texel(param_1);\n    vec2 _1821 = _1818.yz;\n    int _1825 = int(_1818.w);\n    int param_2 = _1814 + 1;\n    vec4 _1830 = fa_light_texel(param_2);\n    float _1831 = _1830.x;\n    int _1837 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1841 = int(_1800.z);\n    vec3 _2106;\n    for (int k = 0; k < _1804; k++)\n    {\n        int _1854 = _1841 + k;\n        int param_3 = _1825 + (_1854 >> 2);\n        int _1871 = (_1814 + 2) + (int(fa_light_texel(param_3)[_1854 & 3]) * 7);\n        int param_4 = _1871 + 6;\n        vec4 _1876 = fa_light_texel(param_4);\n        if (((int(_1876.w + 0.5) >> _1837) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1871;\n        vec4 _1891 = fa_light_texel(param_5);\n        int param_6 = _1871 + 1;\n        vec4 _1896 = fa_light_texel(param_6);\n        int param_7 = _1871 + 2;\n        vec4 _1901 = fa_light_texel(param_7);\n        vec3 _1904 = _1891.xyz;\n        float _1909 = dot(_1904, world_pos) + _1891.w;\n        vec3 _1911 = _1896.xyz;\n        float _1916 = dot(_1911, world_pos) + _1896.w;\n        vec3 _1918 = _1901.xyz;\n        float _1923 = dot(_1918, world_pos) + _1901.w;\n        bool _1928 = abs(_1909) > 0.5;\n        bool _1936;\n        if (!_1928)\n        {\n            _1936 = abs(_1916) > 0.5;\n        }\n        else\n        {\n            _1936 = _1928;\n        }\n        bool _1944;\n        if (!_1936)\n        {\n            _1944 = abs(_1923) > 0.5;\n        }\n        else\n        {\n            _1944 = _1936;\n        }\n        if (_1944)\n        {\n            continue;\n        }\n        float _1959 = clamp(dot(geo_normal, normalize(_1918)) * _1876.z, 0.0, 1.0);\n        if (_1959 <= 0.0)\n        {\n            continue;\n        }\n        float _1979 = (clamp((0.5 - abs(_1923)) * 10.0, 0.0, 1.0) * _1959) * _1876.x;\n        vec2 _1987 = vec2(_1909 + 0.5, 0.5 - _1916);\n        vec2 _1997 = vec2(dot(_1904, _1793), dot(_1911, _1793));\n        vec2 _2007 = vec2(dot(_1904, _1796), dot(_1911, _1796));\n        int param_8 = _1871 + 5;\n        vec4 _2012 = fa_light_texel(param_8);\n        int param_9 = _1871 + 3;\n        vec4 _2017 = fa_light_texel(param_9);\n        int param_10 = _1871 + 4;\n        vec4 _2022 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2012.xyz;\n        bool _2032 = _2017.z > _2017.x;\n        if (_2032)\n        {\n            vec4 param_11 = _2017;\n            vec2 param_12 = _1987;\n            vec2 param_13 = _1821;\n            vec2 param_14 = _1997;\n            vec2 param_15 = _2007;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1831 > 0.5) && (_1831 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2058 = fa_dc_to_linear(param_16);\n                vec4 _7324 = tx;\n                _7324.x = _2058.x;\n                _7324.y = _2058.y;\n                _7324.z = _2058.z;\n                tx = _7324;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1979 * tex_a) * _2012.w, 0.0, 1.0)));\n        if (_2022.z > _2022.x)\n        {\n            vec4 param_17 = _2022;\n            vec2 param_18 = _1987;\n            vec2 param_19 = _1821;\n            vec2 param_20 = _1997;\n            vec2 param_21 = _2007;\n            vec4 _2102 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1831 > 1.5)\n            {\n                vec3 param_22 = _2102.xyz;\n                vec3 _2112 = fa_dc_to_srgb(param_22);\n                _2106 = _2112;\n            }\n            else\n            {\n                _2106 = _2102.xyz;\n            }\n            vec3 _2121 = (_2106 * 2.0) - vec3(1.0);\n            vec2 _2126 = _2121.xy * _1876.y;\n            vec3 _2148 = (normalize(_1904) * _2126.x) + (normalize(_1911) * _2126.y);\n            vec3 _2151 = normalize(normal);\n            normal = normalize(mix(_2151, normalize((_2151 * max(_2121.z, 0.0500000007450580596923828125)) + (_2148 - (_2151 * dot(_2151, _2148)))), vec3(clamp(_1979 * (_2032 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3589 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3596 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3599 = int(_3589);\n    int _3602 = int(_3596);\n    float _3612 = _3596 - float(_3602);\n    int _3667 = (_3599 * 9) + _3602;\n    int _3687 = ((_3599 + 1) * 9) + _3602;\n    return mix(mix(_3663[_3667], _3663[_3667 + 1], _3612), mix(_3663[_3687], _3663[_3687 + 1], _3612), _3589 - float(_3599));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7167 = false;\n    float _7168 = 1.0;\n    float _7169 = 1.0;\n    float _7170 = 1.0;\n    float _7171 = 0.0;\n    float _7172 = 0.0;\n    float _7173 = 0.0;\n    float _7174 = 0.0;\n    float _7176 = 1.0;\n    bool _7177 = false;\n    vec3 _7178 = vec3(0.0);\n    float _7179 = 1.0;\n    float _7180 = 1.0;\n    float _7181 = 1.0;\n    float _7182 = 0.0;\n    float _7183 = 0.0;\n    vec3 _7184 = vec3(1.0, 0.0, 0.0);\n    vec3 _7185 = vec3(0.0, 0.0, 1.0);\n    float _7186 = 1.0;\n    float _7187 = 1.0;\n    float _3738 = clamp(s.specular, 0.0, 1.0);\n    float _3742 = clamp(s.ior, 1.0, 3.0);\n    bool _3747 = (_3738 != 1.0) || (_3742 != 1.5);\n    bool _3756;\n    if (!_3747)\n    {\n        _3756 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3756 = _3747;\n    }\n    if (_3756)\n    {\n        float _3764 = (_3742 - 1.0) / (_3742 + 1.0);\n        f0 = mix(min(vec3(_3764 * _3764) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3738, s.albedo, vec3(metallic));\n        _7168 = mix(_3738, 1.0, metallic);\n        _7167 = true;\n    }\n    float _3791 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3791 > 0.0)\n    {\n        float _3799 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7171 = _3791;\n        _7172 = _3799;\n        float _3806 = _3799 * _3799;\n        _7173 = _3806;\n        _7174 = _3806 * _3806;\n        float _3818 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7176 = _3818;\n        _7169 = 1.0 - (_3791 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3818, 0.0, 1.0), 5.0))));\n        _7167 = true;\n    }\n    vec3 _3837 = max(s.sheen_color, vec3(0.0));\n    float _3846 = max(_3837.x, max(_3837.y, _3837.z));\n    if (_3846 > 0.0)\n    {\n        float _3854 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7177 = true;\n        _7178 = _3837;\n        _7179 = _3854;\n        _7180 = _3854 * _3854;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3854;\n        float _3871 = fa_sheen_albedo(param, param_1);\n        _7182 = _3871;\n        _7181 = 1.0 - min(_3846 * _3871, 1.0);\n        _7167 = true;\n    }\n    _7170 = _7169 * _7181;\n    float _3890 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3890 != 0.0)\n    {\n        vec3 _3905 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3905;\n        if (dot(_3905, _3905) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3917 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3917.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3917.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3917.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3921 = t;\n        vec3 _3922 = normalize(_3921);\n        t = _3922;\n        vec3 _3947 = normalize((_3922 * cos(s.anisotropy_rotation)) + ((cross(n, _3922) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7184 = _3947;\n        _7185 = cross(n, _3947);\n        float _3957 = roughness * roughness;\n        float _3963 = mix(_3957, 1.0, _3890 * _3890);\n        bool _3965 = _3890 > 0.0;\n        _7186 = _3965 ? _3963 : _3957;\n        _7187 = _3965 ? _3957 : _3963;\n        _7183 = _3890;\n        _7167 = true;\n    }\n    return FaLayers(_7167, _7168, _7169, _7170, _7171, _7172, _7173, _7174, i.world_normal, _7176, _7177, _7178, _7179, _7180, _7181, _7182, _7183, _7184, _7185, _7186, _7187);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3346 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3346;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4731;\n    if (fa_lm.z > 0.5)\n    {\n        _4731 = 0.0;\n    }\n    else\n    {\n        _4731 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _4742 = _4731 < 1.0;\n    bool _4748;\n    if (_4742)\n    {\n        int param = li;\n        _4748 = fa_light_baked(param);\n    }\n    else\n    {\n        _4748 = _4742;\n    }\n    return _4748 ? _4731 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _753 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _766 = (c - (ru * hx)) - p;\n        vec3 _772 = ru * (2.0 * hx);\n        float _778 = max(dot(_772, _772), 9.9999999392252902907785028219223e-09);\n        float _782 = dot(_766, _772);\n        float t = clamp((-_782) / _778, 0.0, 1.0);\n        if (_753)\n        {\n            float _797 = dot(r, _772);\n            float _803 = _778 - (_797 * _797);\n            if (abs(_803) > (9.9999997473787516355514526367188e-06 * _778))\n            {\n                t = clamp(((dot(r, _766) * _797) - _782) / _803, 0.0, 1.0);\n            }\n        }\n        return (p + _766) + (_772 * t);\n    }\n    vec3 q = p;\n    float _835 = dot(r, axis);\n    bool _843;\n    if (_753)\n    {\n        _843 = abs(_835) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _843 = _753;\n    }\n    if (_843)\n    {\n        float _853 = dot(c - p, axis) / _835;\n        if (_853 > 0.0)\n        {\n            q = p + (r * _853);\n        }\n    }\n    vec3 _866 = q - c;\n    vec2 xy = vec2(dot(_866, ru), dot(_866, uu));\n    if (shape > 0.5)\n    {\n        float _881 = length(xy);\n        if (_881 > hx)\n        {\n            xy *= (hx / _881);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _514 = abs(d);\n    float _516 = _514.x;\n    float _518 = _514.y;\n    bool _519 = _516 >= _518;\n    bool _527;\n    if (_519)\n    {\n        _527 = _516 >= _514.z;\n    }\n    else\n    {\n        _527 = _519;\n    }\n    int _528;\n    if (_527)\n    {\n        _528 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _543;\n        if (_518 >= _514.z)\n        {\n            _543 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _543 = (d.z > 0.0) ? 4 : 5;\n        }\n        _528 = _543;\n    }\n    return _528;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _673 = dot(d, right);\n    float _677 = dot(d, up);\n    float _688;\n    if (((_673 * _673) + (_677 * _677)) > 1.0000000133514319600180897396058e-10)\n    {\n        _688 = atan(_677, _673) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _688 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_688 - floor(_688)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _919 = fa_light_base(param);\n    bool _923 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _919;\n    vec4 _927 = fa_light_texel(param_1);\n    int param_2 = _919 + 1;\n    vec4 _932 = fa_light_texel(param_2);\n    float _935 = _932.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _947 = _923 && (_935 > 2.5);\n    fa_light_is_area = _947;\n    bool _949 = _935 < 0.5;\n    vec3 l;\n    if (_949)\n    {\n        l = normalize(_927.xyz);\n        if (_923)\n        {\n            int param_3 = _919 + 6;\n            vec4 _963 = fa_light_texel(param_3);\n            if (_963.z > 0.5)\n            {\n                int param_4 = _919 + 4;\n                vec4 _973 = fa_light_texel(param_4);\n                int param_5 = _919 + 5;\n                vec4 _978 = fa_light_texel(param_5);\n                vec2 param_6 = _963.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _973.xyz) * _973.w, (-dot(world_pos, _978.xyz)) * _978.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1008 = _927.xyz;\n        vec3 _1010 = _1008 - world_pos;\n        vec3 to_light = _1010;\n        float _1013 = length(_1010);\n        float reach = _1013;\n        bool front = true;\n        if (_947)\n        {\n            int param_8 = _919 + 7;\n            reach = max(_1013 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _919 + 4;\n            vec4 _1037 = fa_light_texel(param_9);\n            int param_10 = _919 + 5;\n            vec4 _1042 = fa_light_texel(param_10);\n            int param_11 = _919 + 6;\n            vec4 _1047 = fa_light_texel(param_11);\n            float _1048 = _1047.w;\n            int param_12 = _919 + 2;\n            vec3 _1055 = normalize(fa_light_texel(param_12).xyz);\n            bool _1057 = _1048 > 1.5;\n            bool _1065;\n            if (!_1057)\n            {\n                _1065 = dot(_1055, to_light) < 0.0;\n            }\n            else\n            {\n                _1065 = _1057;\n            }\n            front = _1065;\n            vec3 r = vec3(0.0);\n            vec3 _1074 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1078 = dot(n, n) > 0.5;\n            bool _1086;\n            if (_1078)\n            {\n                _1086 = dot(_1074, _1074) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1086 = _1078;\n            }\n            if (_1086)\n            {\n                r = reflect(-normalize(_1074), normalize(n));\n            }\n            vec3 param_13 = _1008;\n            vec3 param_14 = _1055;\n            vec3 param_15 = _1037.xyz;\n            vec3 param_16 = _1042.xyz;\n            float param_17 = _1037.w;\n            float param_18 = _1042.w;\n            float param_19 = _1048;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1122 = length(to_light);\n        dist = _1122;\n        l = to_light / vec3(max(_1122, 9.9999997473787516355514526367188e-05));\n        float _1136 = reach / max(_927.w, 0.001000000047497451305389404296875);\n        float _1142 = clamp(1.0 - (_1136 * _1136), 0.0, 1.0);\n        float _1144;\n        if (front)\n        {\n            _1144 = _1142 * _1142;\n        }\n        else\n        {\n            _1144 = 0.0;\n        }\n        atten = _1144;\n        bool _1155 = _935 < 2.5;\n        if ((_935 > 1.5) && _1155)\n        {\n            int param_22 = _919 + 2;\n            vec4 _1163 = fa_light_texel(param_22);\n            float _1173 = _1163.w;\n            int param_23 = _919 + 3;\n            vec4 _1178 = fa_light_texel(param_23);\n            float _1179 = _1178.x;\n            float cos_inner = _1179;\n            if (_1179 > 1.5)\n            {\n                cos_inner = mix(_1173, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1173, cos_inner, dot(-l, normalize(_1163.xyz)));\n        }\n        if (_923 && (_935 < 1.5))\n        {\n            int param_24 = _919 + 6;\n            vec4 _1203 = fa_light_texel(param_24);\n            if (_1203.z > 0.5)\n            {\n                vec3 _1211 = -to_light;\n                int param_25 = _919 + 4;\n                int param_26 = _919 + 5;\n                vec3 _1225 = fa_light_texel(param_25).xyz;\n                vec3 _1229 = fa_light_texel(param_26).xyz;\n                vec3 _1238 = vec3(dot(_1211, _1225), dot(_1211, _1229), dot(_1211, cross(_1225, _1229)));\n                vec3 param_27 = _1238;\n                int _1242 = fa_cube_face(param_27);\n                int param_28 = _1242;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1269 = vec2(dot(_1238, cross(param_29, param_30)), dot(_1238, param_30)) / vec2(max(dot(_1238, param_29), 9.9999997473787516355514526367188e-05));\n                int _1273 = _1242 / 3;\n                vec2 param_31 = _1203.xy + (vec2(float(_1242 - (_1273 * 3)), float(_1273)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1269.x), 0.5 - (0.5 * _1269.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _919 + 7;\n            vec4 _1303 = fa_light_texel(param_33);\n            if (_1303.z > 0.5)\n            {\n                int param_34 = _919 + 2;\n                int param_35 = _919 + 4;\n                int param_36 = _919 + 5;\n                vec2 param_37 = _1303.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_923 && _1155)\n            {\n                int param_42 = _919 + 6;\n                vec4 _1350 = fa_light_texel(param_42);\n                int param_43 = _919 + 7;\n                vec4 _1355 = fa_light_texel(param_43);\n                bool _1358 = _1350.z > 0.5;\n                bool _1365;\n                if (!_1358)\n                {\n                    _1365 = _1355.z > 0.5;\n                }\n                else\n                {\n                    _1365 = _1358;\n                }\n                if (_1365)\n                {\n                    int param_44 = _919 + 2;\n                    vec4 _1372 = fa_light_texel(param_44);\n                    vec3 _1376 = normalize(_1372.xyz);\n                    int param_45 = _919 + 4;\n                    vec4 _1381 = fa_light_texel(param_45);\n                    int param_46 = _919 + 5;\n                    vec4 _1386 = fa_light_texel(param_46);\n                    if (_1358)\n                    {\n                        vec3 _1394 = -to_light;\n                        float _1401 = _1372.w;\n                        float _1417 = 0.5 / max(dot(_1394, _1376) * (sqrt(max(1.0 - (_1401 * _1401), 0.0)) / max(_1401, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1350.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1394, _1381.xyz) * _1417), 0.5 - (dot(_1394, _1386.xyz) * _1417));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1355.z > 0.5)\n                    {\n                        vec2 param_49 = _1355.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1376;\n                        vec3 param_52 = _1381.xyz;\n                        vec3 param_53 = _1386.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7155 = _932.xyz * atten;\n    if (_923)\n    {\n        _7155 *= fa_light_tint;\n    }\n    int _1486;\n    if (_949)\n    {\n        _1486 = 0;\n    }\n    else\n    {\n        _1486 = ((_935 > 1.5) && (_935 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7155, atten, 1.0, dist, _1486);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2223;\n    if (i == 0)\n    {\n        _2223 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2239;\n        if (i == 1)\n        {\n            _2239 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2247;\n            if (i == 2)\n            {\n                _2247 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2247 = fa_shadows[24].w;\n            }\n            _2239 = _2247;\n        }\n        _2223 = _2239;\n    }\n    return _2223;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2280 = fa_shadow_depth(param, param_1);\n    float _2284;\n    if (conv.x < 0.5)\n    {\n        _2284 = _2280;\n    }\n    else\n    {\n        _2284 = (conv.y * conv.z) / (conv.z - (_2280 * (conv.z - conv.y)));\n    }\n    return _2284;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2211 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2211), sin(_2211)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2330 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2339;\n        if (k < 0.0)\n        {\n            _2339 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2339 = k;\n        }\n        float _2359 = clamp((_2339 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2330;\n            vec2 _2378 = fa_shadow_vogel(param_3, param_4, param_5) * _2359;\n            vec2 param_6 = uv + (_2378 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2390 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2390 < (zr - (length(_2378) * plane)))\n            {\n                sum += _2390;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2416 = sum / cnt;\n        float _2426;\n        if (k < 0.0)\n        {\n            _2426 = (-k) / max(_2416, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2426 = k;\n        }\n        radius = clamp(((max(zr - _2416, 0.0) * unit) * _2426) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2448 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2448; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2448;\n        float param_11 = _2330;\n        vec2 _2467 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2467 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2467) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2448);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2509 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2514 = clamp(dot(n, l), 0.0, 1.0);\n    float _2520 = sqrt(1.0 - (_2514 * _2514));\n    float _2527 = min(_2520 / max(_2514, 0.20000000298023223876953125), 4.0);\n    float _2532;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2532 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2532 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2557 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2532 * _2520)), 1.0);\n    float _2564 = _2557.x;\n    bool _2567 = _2564 < fa_shadows[ci * 1 + 16].x;\n    bool _2576;\n    if (!_2567)\n    {\n        _2576 = _2564 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2576 = _2567;\n    }\n    bool _2585;\n    if (!_2576)\n    {\n        _2585 = _2557.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2585 = _2576;\n    }\n    bool _2594;\n    if (!_2585)\n    {\n        _2594 = _2557.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2594 = _2585;\n    }\n    bool _2601;\n    if (!_2594)\n    {\n        _2601 = _2557.z > 1.0;\n    }\n    else\n    {\n        _2601 = _2594;\n    }\n    if (_2601)\n    {\n        return -1.0;\n    }\n    float _2609;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2609 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2609 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2557.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2557.z - ((_2609 * (1.0 + (0.5 * _2527))) / _2509);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2509;\n    float param_5 = _2509 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2527, 3.0)) * 0.5) / _2509;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2987 = int(fa_shadows[25].x + 0.5);\n    if (_2987 < 1)\n    {\n        return 1.0;\n    }\n    float _3002 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2987 - 1;\n    if (_3002 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3014 = _2987 > 1;\n    bool _3021;\n    if (_3014)\n    {\n        _3021 = _3002 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3021 = _3014;\n    }\n    if (_3021)\n    {\n        ci = 1;\n    }\n    bool _3025 = _2987 > 2;\n    bool _3032;\n    if (_3025)\n    {\n        _3032 = _3002 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3032 = _3025;\n    }\n    if (_3032)\n    {\n        ci = 2;\n    }\n    bool _3036 = _2987 > 3;\n    bool _3043;\n    if (_3036)\n    {\n        _3043 = _3002 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3043 = _3036;\n    }\n    if (_3043)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2987)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3069 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3069;\n        if (_3069 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3094;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3094 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3094 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3113 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3094, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3124 = clamp((_3002 - (fa_shadow_split_at(param_7) - _3113)) / _3113, 0.0, 1.0);\n        if (_3124 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2987)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3145 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3145;\n                if (_3145 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3124);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2667 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2674;\n    if (!_2667)\n    {\n        _2674 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2674 = _2667;\n    }\n    if (_2674)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2687 = fa_light_texel(param);\n    float _2688 = _2687.x;\n    if (_2688 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2697 = int(_2688 + 0.5);\n    int param_1 = _2697;\n    vec4 _2701 = fa_light_texel(param_1);\n    int param_2 = _2697 + 1;\n    vec4 _2706 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2709 = _2701.y;\n    if (_2709 > 0.0)\n    {\n        float _2726 = 1.0 - smoothstep(0.75 * _2709, _2709, length(world - fa_shadows[27].xyz));\n        fade = _2726;\n        if (_2726 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2701.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2750 = (_2697 + 2) + (face * 6);\n    int param_4 = _2750;\n    int param_5 = _2750 + 1;\n    int param_6 = _2750 + 3;\n    vec4 _2764 = fa_light_texel(param_6);\n    int param_7 = _2750 + 4;\n    vec4 _2769 = fa_light_texel(param_7);\n    int param_8 = _2750 + 5;\n    vec4 _2774 = fa_light_texel(param_8);\n    float _2786 = _2774.x * max(dot(_2764, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2791 = clamp(dot(n, l), 0.0, 1.0);\n    float _2814 = clamp(dot(n, _2764.xyz), -1.0, 1.0);\n    float _2833 = min(sqrt(1.0 - (_2814 * _2814)) / max(abs(dot(n, world - lpos)) / max(dot(_2764, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2836 = _2706.y;\n    float _2838;\n    if (_2836 > 0.0)\n    {\n        _2838 = _2836;\n    }\n    else\n    {\n        _2838 = 1.5 * _2786;\n    }\n    vec4 _2858 = vec4(world + (n * (_2838 * sqrt(1.0 - (_2791 * _2791)))), 1.0);\n    float _2862 = dot(_2764, _2858);\n    float _2865 = _2774.y;\n    if (_2862 < _2865)\n    {\n        return 1.0;\n    }\n    vec2 _2880 = vec2(dot(fa_light_texel(param_4), _2858), dot(fa_light_texel(param_5), _2858)) / vec2(_2862);\n    float _2882 = _2880.x;\n    bool _2885 = _2882 < _2769.x;\n    bool _2894;\n    if (!_2885)\n    {\n        _2894 = _2882 > _2769.z;\n    }\n    else\n    {\n        _2894 = _2885;\n    }\n    bool _2903;\n    if (!_2894)\n    {\n        _2903 = _2880.y < _2769.y;\n    }\n    else\n    {\n        _2903 = _2894;\n    }\n    bool _2912;\n    if (!_2903)\n    {\n        _2912 = _2880.y > _2769.w;\n    }\n    else\n    {\n        _2912 = _2903;\n    }\n    if (_2912)\n    {\n        return 1.0;\n    }\n    float _2918 = _2706.x;\n    float _2920;\n    if (_2918 > 0.0)\n    {\n        _2920 = _2918;\n    }\n    else\n    {\n        _2920 = 1.5 * _2786;\n    }\n    vec2 param_9 = _2880;\n    vec4 param_10 = _2769;\n    float param_11 = _2862 - (_2920 * (1.0 + (0.5 * _2833)));\n    float param_12 = _2786;\n    float param_13 = 1.0;\n    float param_14 = _2774.z * 0.25;\n    float param_15 = (_2786 * min(_2833, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2865, _2774.z);\n    int param_17 = int(_2701.z + 0.5);\n    float param_18 = _2701.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4475 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4482;\n    if (!_4475)\n    {\n        _4482 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4482 = _4475;\n    }\n    if (_4482)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4495 = fa_light_texel(param);\n    float _4496 = _4495.y;\n    float len = _4496;\n    if (_4496 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4508 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4518 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4508);\n    if (_4518 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4524 = len;\n    float _4527 = min(_4524, 0.89999997615814208984375 * dist);\n    len = _4527;\n    float _4532 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4508);\n    float _4537 = _4532 + (0.5 * _4527);\n    vec3 _4543 = world + (gn * _4532);\n    float _4545 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4609;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4560 = (float(k) + _4545) * 0.083333335816860198974609375;\n        vec3 _4568 = _4543 + (l * (_4560 * len));\n        vec4 _4574 = vec4(_4568, 1.0);\n        float _4580 = dot(fa_mesh_fs_params[28], _4574);\n        if (_4580 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4600 = vec2(dot(fa_mesh_fs_params[26], _4574), dot(fa_mesh_fs_params[27], _4574)) / vec2(_4580);\n        float _4604 = _4600.x * 0.5;\n        float _4605 = _4604 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4609 = (_4600.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4609 = 0.5 - (_4600.y * 0.5);\n        }\n        bool _4625 = _4605 < 0.0;\n        bool _4632;\n        if (!_4625)\n        {\n            _4632 = _4605 >= 1.0;\n        }\n        else\n        {\n            _4632 = _4625;\n        }\n        bool _4639;\n        if (!_4632)\n        {\n            _4639 = _4609 < 0.0;\n        }\n        else\n        {\n            _4639 = _4632;\n        }\n        bool _4646;\n        if (!_4639)\n        {\n            _4646 = _4609 >= 1.0;\n        }\n        else\n        {\n            _4646 = _4639;\n        }\n        if (_4646)\n        {\n            break;\n        }\n        vec4 _4665 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4605, _4609) * fa_mesh_fs_params[24].zw), 0);\n        if (_4665.w < 0.5)\n        {\n            continue;\n        }\n        float _4684 = (dot(fa_mesh_fs_params[29].xyz, _4568) + fa_mesh_fs_params[29].w) - _4665.x;\n        if ((_4684 > _4532) && (_4684 < _4537))\n        {\n            occ = max(occ, (1.0 - (_4560 * _4560)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4605, 0.5 - _4604), min(_4609, 1.0 - _4609))));\n        }\n    }\n    return 1.0 - (occ * _4518);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4787 = fa_baked_keep(param);\n    if (_4787 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4813 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7224 = _4813.color;\n    float _7225 = _4813.attenuation;\n    float _7226 = _4813.shadow;\n    bool _4816 = _4813.type == 0;\n    if (_4816 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4813.direction;\n        float _4827 = fa_shadow_factor(param_5, param_6);\n        _7226 = _4827;\n        _7224 *= _4827;\n    }\n    else\n    {\n        bool _4838 = _4813.type != 0;\n        bool _4844;\n        if (_4838)\n        {\n            _4844 = _7225 > 0.0;\n        }\n        else\n        {\n            _4844 = _4838;\n        }\n        if (_4844)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4813.direction;\n            float _4863 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7226 = _4863;\n            _7224 *= _4863;\n        }\n    }\n    bool _4873 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4879;\n    if (_4873)\n    {\n        _4879 = _7225 > 0.0;\n    }\n    else\n    {\n        _4879 = _4873;\n    }\n    if (_4879)\n    {\n        float _4886;\n        if (_4816)\n        {\n            _4886 = 1000000000.0;\n        }\n        else\n        {\n            _4886 = _4813._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4813.direction;\n        float param_18 = _4886;\n        float _4904 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7226 *= _4904;\n        _7224 *= _4904;\n    }\n    float _4917 = _7225;\n    float _4918 = _4917 * _4787;\n    _7225 = _4918;\n    return LightSample(_4813.direction, _7224, _4918, _7226, _4813._distance, _4813.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _4952 = v - (n * dot(v, n));\n    vec3 t = _4952;\n    float _4956 = dot(_4952, _4952);\n    float l2 = _4956;\n    if (_4956 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _4966;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _4966 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _4966 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _4966;\n        l2 = dot(_4966, _4966);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5001 = dot(a, a);\n    float _5005 = dot(b, b);\n    if ((_5001 < 1.0000000195414813782625560981111e-24) || (_5005 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5019 = a * inversesqrt(_5001);\n    vec3 _5024 = b * inversesqrt(_5005);\n    float _5028 = dot(_5019, _5024);\n    float _5031 = abs(_5028);\n    float g = (((((((((((0.0416471660137176513671875 * _5031) - 0.1924748718738555908203125) * _5031) + 0.4179156124591827392578125) * _5031) - 0.616057217121124267578125) * _5031) + 0.777722418308258056640625) * _5031) - 0.999542415142059326171875) * _5031) + 1.570791721343994140625;\n    if (_5028 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5028 * _5028), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5019, _5024) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5088 = a.z > 0.0;\n    bool _5092 = b.z > 0.0;\n    if (_5088 && _5092)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5088 != _5092)\n        {\n            vec3 _5127 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5127.z = 0.0;\n            if (_5088)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5127;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5127;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5127;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5127;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5176 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5202 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5228 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5254 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5176;\n    vec3 param_1 = _5202;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5202;\n    vec3 param_7 = _5228;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5228;\n    vec3 param_13 = _5254;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5254;\n    vec3 param_19 = _5176;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5404 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5428 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5444 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5404;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5428;\n    vec4 param_9 = m;\n    vec3 param_10 = _5404;\n    vec3 param_11 = _5428;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5444;\n    vec4 param_14 = m;\n    vec3 param_15 = _5404;\n    vec3 param_16 = _5444;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5502 = fa_light_base(param);\n    int param_1 = _5502;\n    int param_2 = _5502 + 1;\n    int param_3 = _5502 + 2;\n    int param_4 = _5502 + 4;\n    vec4 _5524 = fa_light_texel(param_4);\n    int param_5 = _5502 + 5;\n    vec4 _5529 = fa_light_texel(param_5);\n    int param_6 = _5502 + 6;\n    vec4 _5534 = fa_light_texel(param_6);\n    float _5535 = _5534.w;\n    vec3 _5540 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5542 = _5535 < 1.5;\n    bool _5549;\n    if (_5542)\n    {\n        _5549 = dot(normalize(fa_light_texel(param_3).xyz), _5540) >= 0.0;\n    }\n    else\n    {\n        _5549 = _5542;\n    }\n    if (_5549)\n    {\n        return vec3(0.0);\n    }\n    bool _5558 = (_5535 > 0.5) && _5542;\n    float _5562 = _5558 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5565 = _5524.xyz;\n    float _5567 = _5524.w;\n    vec3 _5573 = _5529.xyz;\n    float _5575 = _5529.w;\n    vec3 up = _5573 * (_5575 * _5562);\n    float _5581;\n    if (_5558)\n    {\n        _5581 = (3.1415927410125732421875 * _5567) * _5567;\n    }\n    else\n    {\n        _5581 = (4.0 * _5567) * _5575;\n    }\n    if (_5535 > 1.5)\n    {\n        vec3 _5607 = cross(_5565, -_5540);\n        vec3 perp = _5607;\n        float _5611 = dot(_5607, _5607);\n        vec3 _5614;\n        if (_5611 > 1.0000000133514319600180897396058e-10)\n        {\n            _5614 = perp * inversesqrt(_5611);\n        }\n        else\n        {\n            _5614 = _5573;\n        }\n        perp = _5614;\n        up = _5614 * _5575;\n    }\n    float _5635 = max(_5581, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _5645 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _5645;\n    vec3 param_10 = n;\n    vec3 param_11 = _5540;\n    vec3 _5653 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _5645;\n    vec3 param_13 = n;\n    vec3 param_14 = _5565 * (_5567 * _5562);\n    vec3 _5661 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _5645;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _5669 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5535;\n    vec3 param_20 = _5653;\n    vec3 param_21 = _5661;\n    vec3 param_22 = _5669;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _5688 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _5688;\n    vec2 param_26 = _5688 + vec2(64.0, 0.0);\n    vec4 _5698 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5535;\n    vec3 param_29 = _5653;\n    vec3 param_30 = _5661;\n    vec3 param_31 = _5669;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _5698.x) + ((vec3(f90) - f0) * _5698.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5540, _5540)) + _5635) / _5635) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4212 = 1.0 / alpha;\n    return ((2.0 + _4212) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4212)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4247 = max(dot(L.nc, l), 0.0);\n    float _4253 = max(dot(L.nc, h), 0.0);\n    float _4262 = ((_4253 * _4253) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4262) * _4262)) * (0.5 / max(mix((2.0 * _4247) * L.coat_ndv, _4247 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4247)) * _4247;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _5766;\n    if (L.sheen_on)\n    {\n        _5766 = L.sheen_scale;\n    }\n    else\n    {\n        _5766 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _5766);\n    vec3 _5779 = normalize(l + v);\n    int param_10 = li;\n    vec3 _5790 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _5799 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _5779), 0.0);\n        float param_13 = _5799;\n        float param_14 = ndv;\n        result += ((L.sheen * _5790) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _5799)) * _5799) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _5779;\n        float param_18 = max(dot(v, _5779), 0.0);\n        result += (_5790 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4115 = tdh / at;\n    float _4119 = bdh / ab;\n    float _4131 = ((_4115 * _4115) + (_4119 * _4119)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4131) * _4131);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4311 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4390 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4390) * _4390);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4311);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4311));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3521 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3524 = _3521.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3524 * _3524, exp2((-9.27999973297119140625) * ndv)) * _3524) + _3521.y)) + _3521.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3375 = rough * rough;\n    float _3405 = 0.60000002384185791015625 * _3375;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3375)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3405, 0.0500000007450580596923828125 + _3405, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3375 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3998;\n        if (L.aniso >= 0.0)\n        {\n            _3998 = L.b;\n        }\n        else\n        {\n            _3998 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3998, v), _3998), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4031 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4031.x) + (vec3(L.f90) * _4031.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4086 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4086.x) + _4086.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3563 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3563.x) + vec3(_3563.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3169 = int(fa_shadows[25].x + 0.5);\n    float _3179 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint_1 = vec3(0.3499999940395355224609375);\n    bool _3184 = _3169 > 0;\n    bool _3193;\n    if (_3184)\n    {\n        int param = _3169 - 1;\n        _3193 = _3179 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3193 = _3184;\n    }\n    if (_3193)\n    {\n        tint_1 = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3199 = _3169 > 1;\n        bool _3206;\n        if (_3199)\n        {\n            _3206 = _3179 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3206 = _3199;\n        }\n        if (_3206)\n        {\n            tint_1 = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3212 = _3169 > 2;\n        bool _3219;\n        if (_3212)\n        {\n            _3219 = _3179 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3219 = _3212;\n        }\n        if (_3219)\n        {\n            tint_1 = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3225 = _3169 > 3;\n        bool _3232;\n        if (_3225)\n        {\n            _3232 = _3179 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3232 = _3225;\n        }\n        if (_3232)\n        {\n            tint_1 = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint_1, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6924 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6924 = -_6924;\n    }\n    vec3 _6287 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6924, fa_world_tangent, fa_uv, fa_vertex_color, _6287, gl_FrontFacing);\n    Surface _6295 = fa_standard_surface(param_1);\n    vec3 _6955 = _6295.albedo;\n    float _6956 = _6295.alpha;\n    vec3 _6957 = _6295.normal;\n    float _6958 = _6295.metallic;\n    float _6959 = _6295.roughness;\n    float _6960 = _6295.occlusion;\n    vec3 _6961 = _6295.emission;\n    float _6962 = _6295.clearcoat;\n    float _6963 = _6295.clearcoat_roughness;\n    vec3 _6964 = _6295.sheen_color;\n    float _6965 = _6295.sheen_roughness;\n    float _6966 = _6295.anisotropy;\n    float _6967 = _6295.anisotropy_rotation;\n    float _6968 = _6295.specular;\n    float _6969 = _6295.ior;\n    vec3 _6970 = _6295.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6924, fa_world_tangent, fa_uv, fa_vertex_color, _6287, gl_FrontFacing);\n    Surface param_3 = _6295;\n    surface(param_2, param_3);\n    _6955 = param_3.albedo;\n    _6956 = param_3.alpha;\n    _6957 = param_3.normal;\n    _6958 = param_3.metallic;\n    _6959 = param_3.roughness;\n    _6960 = param_3.occlusion;\n    _6961 = param_3.emission;\n    _6962 = param_3.clearcoat;\n    _6963 = param_3.clearcoat_roughness;\n    _6964 = param_3.sheen_color;\n    _6965 = param_3.sheen_roughness;\n    _6966 = param_3.anisotropy;\n    _6967 = param_3.anisotropy_rotation;\n    _6968 = param_3.specular;\n    _6969 = param_3.ior;\n    _6970 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6924;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6955 = param_6;\n    _6957 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6955;\n    }\n    else\n    {\n        vec3 _6334 = normalize(_6957);\n        float _6341 = clamp(_6958, 0.0, 1.0);\n        float _6345 = clamp(_6959, 0.0500000007450580596923828125, 1.0);\n        float _6349 = _6345 * _6345;\n        float _6353 = _6349 * _6349;\n        float _6358 = max(dot(_6334, _6287), 9.9999997473787516355514526367188e-05);\n        vec3 _6364 = _6955 * (1.0 - _6341);\n        vec3 _6371 = mix(vec3(0.039999999105930328369140625), _6955, vec3(_6341));\n        vec3 f0 = _6371;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _6924, fa_world_tangent, fa_uv, fa_vertex_color, _6287, gl_FrontFacing);\n        Surface param_9 = Surface(_6955, _6956, _6957, _6958, _6959, _6960, _6961, _6962, _6963, _6964, _6965, _6966, _6967, _6968, _6969, _6970);\n        vec3 param_10 = _6334;\n        vec3 param_11 = _6287;\n        float param_12 = _6341;\n        float param_13 = _6345;\n        vec3 param_14 = _6371;\n        FaLayers _6387 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6334;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6364) * _6960;\n        if (_6387.on)\n        {\n            lit *= _6387.base_scale;\n        }\n        int _6409 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6409; ln++)\n        {\n            int param_16 = ln;\n            int _6422 = fa_cl_light(param_16);\n            int param_17 = _6422;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _6422;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _6924;\n            LightSample _6438 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6446 = max(dot(_6334, _6438.direction), 0.0);\n            float _6452 = _6438.attenuation * _6438.shadow;\n            vec3 _6457 = normalize(_6438.direction + _6287);\n            float _6462 = max(dot(_6334, _6457), 0.0);\n            float _6467 = max(dot(_6287, _6457), 0.0);\n            bool _6474;\n            if (fa_light_is_area)\n            {\n                _6474 = !_6387.on;\n            }\n            else\n            {\n                _6474 = fa_light_is_area;\n            }\n            if (_6474)\n            {\n                int param_21 = _6422;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6334;\n                vec3 param_24 = _6287;\n                vec3 param_25 = _6364;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6345;\n                float param_29 = _6358;\n                float param_30 = _6452;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6387;\n                    int param_32 = _6422;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6334;\n                    vec3 param_35 = _6287;\n                    vec3 param_36 = _6438.direction;\n                    vec3 param_37 = _6364;\n                    vec3 param_38 = f0;\n                    float param_39 = _6345;\n                    float param_40 = _6358;\n                    float param_41 = _6452;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6387.on)\n                    {\n                        FaLayers param_42 = _6387;\n                        vec3 param_43 = _6364;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6334;\n                        vec3 param_46 = _6287;\n                        vec3 param_47 = _6438.direction;\n                        vec3 param_48 = _6457;\n                        float param_49 = _6446;\n                        float param_50 = _6358;\n                        float param_51 = _6462;\n                        float param_52 = _6467;\n                        float param_53 = _6349;\n                        float param_54 = _6353;\n                        int param_55 = _6422;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6452));\n                    }\n                    else\n                    {\n                        float _6580 = ((_6462 * _6462) * (_6353 - 1.0)) + 1.0;\n                        int param_56 = _6422;\n                        lit += (((_6364 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6467, 5.0))) * (((_6353 / ((3.1415927410125732421875 * _6580) * _6580)) * (0.5 / max(mix((2.0 * _6446) * _6358, _6446 + _6358, _6349), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6446))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6446 * _6452));\n                    }\n                }\n            }\n        }\n        if (_6387.on)\n        {\n            FaLayers param_57 = _6387;\n            vec3 param_58 = _6334;\n            vec3 param_59 = _6287;\n            vec3 param_60 = f0;\n            float param_61 = _6345;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _6960);\n        }\n        else\n        {\n            vec3 param_62 = _6334;\n            vec3 param_63 = _6287;\n            vec3 param_64 = f0;\n            float param_65 = _6345;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _6960);\n        }\n        result = lit;\n    }\n    vec3 _6675 = result;\n    vec3 _6676 = _6675 + _6961;\n    result = _6676;\n    vec3 param_66 = _6676;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _6685 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6692;\n    if (!_6685)\n    {\n        _6692 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6692 = _6685;\n    }\n    if (_6692)\n    {\n        vec3 _6701 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6707 = dot(_6701, fa_mesh_fs_params[9].xyz);\n        bool _6711 = fa_mesh_fs_params[9].w > 0.5;\n        float _6712;\n        if (_6711)\n        {\n            _6712 = _6707;\n        }\n        else\n        {\n            _6712 = length(_6701);\n        }\n        float _6724 = _6712 - fa_mesh_fs_params[8].x;\n        if (_6724 > 0.0)\n        {\n            float _6733 = fa_mesh_fs_params[7].w * _6724;\n            float tau = _6733 * _6733;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6749;\n                if (_6711)\n                {\n                    _6749 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6707);\n                }\n                else\n                {\n                    _6749 = fa_mesh_fs_params[0].y;\n                }\n                float _6770 = mix(_6749, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6712, 0.0, 1.0));\n                float _6774 = fa_world_pos.y - _6770;\n                float _6779 = _6770 - fa_mesh_fs_params[8].z;\n                float _6784 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6787 = _6779 <= 0.0;\n                bool _6788 = !_6787;\n                bool _6794;\n                if (_6788)\n                {\n                    _6794 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6794 = _6787;\n                }\n                float _6795;\n                if (_6794)\n                {\n                    _6795 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6795 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6779, 80.0));\n                }\n                bool _6822;\n                if (_6788)\n                {\n                    _6822 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6822 = _6787;\n                }\n                float _6823;\n                if (_6822)\n                {\n                    _6823 = fa_mesh_fs_params[8].y * _6779;\n                }\n                else\n                {\n                    _6823 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6779, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6848 = _6784 <= 0.0;\n                bool _6855;\n                if (!_6848)\n                {\n                    _6855 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6855 = _6848;\n                }\n                float _6856;\n                if (_6855)\n                {\n                    _6856 = fa_mesh_fs_params[8].y * _6784;\n                }\n                else\n                {\n                    _6856 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6784, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6883;\n                if (abs(_6774) < 0.001000000047497451305389404296875)\n                {\n                    _6883 = _6795;\n                }\n                else\n                {\n                    _6883 = (_6856 - _6823) / _6774;\n                }\n                tau += (_6724 * max(_6883, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6956);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_566",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
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
            "inst_name": "_2233",
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
            "inst_name": "_5868",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[39];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _774 = base_t;\n    _774.x = _266.x;\n    _774.y = _266.y;\n    _774.z = _266.z;\n    base_t = _774;\n    vec4 _282 = (_774 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _737 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _782 = _319;\n        _782.x = _324.x;\n        _782.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _782;\n        _737 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _785 = mrt;\n    _785.x = _353.x;\n    _785.y = _353.y;\n    _785.z = _353.z;\n    mrt = _785;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _742 = fa_mesh_fs_params[20].x;\n    float _743 = fa_mesh_fs_params[20].y;\n    float _746 = fa_mesh_fs_params[20].z;\n    float _745 = fa_mesh_fs_params[21].w;\n    float _748 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _742 *= _395.y;\n            _743 *= _395.z;\n            _745 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _746 *= mrt.x;\n            _748 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _737, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _742, _743, fa_mesh_fs_params[21].xyz, _745, _746, fa_mesh_fs_params[20].w, _748, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _648 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _648 = -_648;\n    }\n    vec3 _558 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _573 = normalize(param_2.normal);\n    vec3 _588 = normalize(vec3(dot(fa_pre_r0, _573), dot(fa_pre_r1, _573), dot(fa_pre_r2, _573)));\n    float _600 = _588.z;\n    vec2 e = _588.xy / vec2((abs(_588.x) + abs(_588.y)) + abs(_600));\n    if (_600 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_material[1];\nuniform vec4 fa_mesh_fs_params[39];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) flat in vec4 fa_inst_v0;\nlayout(location = 1) flat in vec4 fa_inst_v1;\nlayout(location = 2) in vec3 fa_world_pos;\nlayout(location = 3) in vec3 fa_world_normal;\nlayout(location = 4) in vec4 fa_world_tangent;\nlayout(location = 5) in vec2 fa_uv;\nlayout(location = 6) in vec4 fa_vertex_color;\nlayout(location = 8) in vec3 fa_pre_r0;\nlayout(location = 9) in vec3 fa_pre_r1;\nlayout(location = 10) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 7) in float fa_pre_depth;\nfloat raise;\nvec4 tint;\n\nvoid fa_instance_unpack(vec4 fa_d0, vec4 fa_d1, vec4 fa_d2)\n{\n    raise = fa_d0.x;\n    tint = fa_d1;\n}\n\nvoid fa_inst_load()\n{\n    vec4 param = fa_inst_v0;\n    vec4 param_1 = fa_inst_v1;\n    vec4 param_2 = vec4(0.0);\n    fa_instance_unpack(param, param_1, param_2);\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _212 = fa_linear_to_srgb(param);\n        c = _212;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _221 = fa_srgb_to_linear(param_1);\n            c = _221;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _63;\n    if (i.front_facing)\n    {\n        _63 = i.world_normal;\n    }\n    else\n    {\n        _63 = -i.world_normal;\n    }\n    vec3 _87 = normalize(i.world_tangent.xyz - (_63 * dot(_63, i.world_tangent.xyz)));\n    vec3 _115 = normalize(((_87 * m.x) + ((cross(_63, _87) * i.world_tangent.w) * m.y)) + (_63 * m.z));\n    vec3 _118;\n    if (i.front_facing)\n    {\n        _118 = _115;\n    }\n    else\n    {\n        _118 = -_115;\n    }\n    return _118;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _266 = fa_tex_fix(param_2, param_3);\n    vec4 _774 = base_t;\n    _774.x = _266.x;\n    _774.y = _266.y;\n    _774.z = _266.z;\n    base_t = _774;\n    vec4 _282 = (_774 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _737 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _315 = fa_tex_fix(param_6, param_7);\n        vec3 _319 = (_315 * 2.0) - vec3(1.0);\n        vec2 _324 = _319.xy * fa_mesh_fs_params[6].x;\n        vec3 _782 = _319;\n        _782.x = _324.x;\n        _782.y = _324.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _782;\n        _737 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _353 = fa_tex_fix(param_12, param_13);\n    vec4 _785 = mrt;\n    _785.x = _353.x;\n    _785.y = _353.y;\n    _785.z = _353.z;\n    mrt = _785;\n    vec4 _383 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _383.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _395 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _425 = fa_tex_fix(param_20, param_21);\n    float _742 = fa_mesh_fs_params[20].x;\n    float _743 = fa_mesh_fs_params[20].y;\n    float _746 = fa_mesh_fs_params[20].z;\n    float _745 = fa_mesh_fs_params[21].w;\n    float _748 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _742 *= _395.y;\n            _743 *= _395.z;\n            _745 *= _383.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _746 *= mrt.x;\n            _748 *= mrt.w;\n        }\n    }\n    return Surface(_282.xyz, _282.w, _737, clamp(fa_mesh_fs_params[5].x * _353.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _353.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_395.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _425), _742, _743, fa_mesh_fs_params[21].xyz, _745, _746, fa_mesh_fs_params[20].w, _748, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += ((tint.xyz * tint.w) * fa_material[0].x);\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _648 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _648 = -_648;\n    }\n    vec3 _558 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _648, fa_world_tangent, fa_uv, fa_vertex_color, _558, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _573 = normalize(param_2.normal);\n    vec3 _588 = normalize(vec3(dot(fa_pre_r0, _573), dot(fa_pre_r1, _573), dot(fa_pre_r2, _573)));\n    float _600 = _588.z;\n    vec2 e = _588.xy / vec2((abs(_588.x) + abs(_588.y)) + abs(_600));\n    if (_600 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_255",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 39,
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
