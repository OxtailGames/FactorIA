{
  "format": "factoria.shader/1",
  "engine": "0.38.0",
  "template": "7dfc96845a84a2e1eeb941c4a325b3e44f1dd63d04807d1dd0da2d9b2c3c7186",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4336[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1426 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1433;\n    if (!_1426)\n    {\n        _1433 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1433 = _1426;\n    }\n    bool _1441;\n    if (!_1433)\n    {\n        _1441 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1441 = _1433;\n    }\n    bool _1448;\n    if (!_1441)\n    {\n        _1448 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1448 = _1441;\n    }\n    bool _1455;\n    if (!_1448)\n    {\n        _1455 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1455 = _1448;\n    }\n    if (_1455)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1465 = vec4(world_pos, 1.0);\n    float _1471 = dot(fa_mesh_fs_params[16], _1465);\n    if (!(_1471 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1493 = vec2(dot(fa_mesh_fs_params[14], _1465), dot(fa_mesh_fs_params[15], _1465)) / vec2(_1471);\n    int _1497 = int(fa_mesh_fs_params[18].x);\n    int _1501 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1501) + clamp(int(floor(((_1493.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1501 - 1)) * _1497)) + clamp(int(floor(((_1493.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1497 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1577 = fa_cluster_texel(param);\n    return ivec2(int(_1577.x), int(_1577.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5151 = fa_cluster_lookup(param);\n    fa_cl_slot = _5151.x;\n    fa_cl_local = _5151.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5363 = fa_linear_to_srgb(param);\n        c = _5363;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5371 = fa_srgb_to_linear(param_1);\n            c = _5371;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _380;\n    if (i.front_facing)\n    {\n        _380 = i.world_normal;\n    }\n    else\n    {\n        _380 = -i.world_normal;\n    }\n    vec3 _404 = normalize(i.world_tangent.xyz - (_380 * dot(_380, i.world_tangent.xyz)));\n    vec3 _431 = normalize(((_404 * m.x) + ((cross(_380, _404) * i.world_tangent.w) * m.y)) + (_380 * m.z));\n    vec3 _434;\n    if (i.front_facing)\n    {\n        _434 = _431;\n    }\n    else\n    {\n        _434 = -_431;\n    }\n    return _434;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5403 = fa_tex_fix(param_2, param_3);\n    vec4 _7305 = base_t;\n    _7305.x = _5403.x;\n    _7305.y = _5403.y;\n    _7305.z = _5403.z;\n    base_t = _7305;\n    vec4 _5417 = (_7305 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7101 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5451 = fa_tex_fix(param_6, param_7);\n        vec3 _5454 = (_5451 * 2.0) - vec3(1.0);\n        vec2 _5459 = _5454.xy * fa_mesh_fs_params[6].x;\n        vec3 _7313 = _5454;\n        _7313.x = _5459.x;\n        _7313.y = _5459.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7313;\n        _7101 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5489 = fa_tex_fix(param_12, param_13);\n    vec4 _7316 = mrt;\n    _7316.x = _5489.x;\n    _7316.y = _5489.y;\n    _7316.z = _5489.z;\n    mrt = _7316;\n    vec4 _5519 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5519.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5530 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5562 = fa_tex_fix(param_20, param_21);\n    float _7106 = fa_mesh_fs_params[20].x;\n    float _7107 = fa_mesh_fs_params[20].y;\n    float _7110 = fa_mesh_fs_params[20].z;\n    float _7109 = fa_mesh_fs_params[21].w;\n    float _7112 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7106 *= _5530.y;\n            _7107 *= _5530.z;\n            _7109 *= _5519.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7110 *= mrt.x;\n            _7112 *= mrt.w;\n        }\n    }\n    return Surface(_5417.xyz, _5417.w, _7101, clamp(fa_mesh_fs_params[5].x * _5489.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5489.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5530.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5562), _7106, _7107, fa_mesh_fs_params[21].xyz, _7109, _7110, fa_mesh_fs_params[20].w, _7112, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1657 = rect.zw - rect.xy;\n    vec2 _1661 = _1657 * atlas;\n    vec2 _1665 = ddx * _1661;\n    vec2 _1669 = ddy * _1661;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1657), clamp(0.5 * log2(max(max(dot(_1665, _1665), dot(_1669, _1669)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1702 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1709;\n    if (!_1702)\n    {\n        _1709 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1709 = _1702;\n    }\n    if (_1709)\n    {\n        return;\n    }\n    vec3 _1715 = dFdx(world_pos);\n    vec3 _1718 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1722 = fa_cluster_texel(param);\n    int _1726 = int(_1722.w);\n    if (_1726 < 1)\n    {\n        return;\n    }\n    int _1736 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1736;\n    vec4 _1740 = fa_light_texel(param_1);\n    vec2 _1743 = _1740.yz;\n    int _1747 = int(_1740.w);\n    int param_2 = _1736 + 1;\n    vec4 _1752 = fa_light_texel(param_2);\n    float _1753 = _1752.x;\n    int _1759 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1763 = int(_1722.z);\n    vec3 _2028;\n    for (int k = 0; k < _1726; k++)\n    {\n        int _1776 = _1763 + k;\n        int param_3 = _1747 + (_1776 >> 2);\n        int _1793 = (_1736 + 2) + (int(fa_light_texel(param_3)[_1776 & 3]) * 7);\n        int param_4 = _1793 + 6;\n        vec4 _1798 = fa_light_texel(param_4);\n        if (((int(_1798.w + 0.5) >> _1759) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1793;\n        vec4 _1813 = fa_light_texel(param_5);\n        int param_6 = _1793 + 1;\n        vec4 _1818 = fa_light_texel(param_6);\n        int param_7 = _1793 + 2;\n        vec4 _1823 = fa_light_texel(param_7);\n        vec3 _1826 = _1813.xyz;\n        float _1831 = dot(_1826, world_pos) + _1813.w;\n        vec3 _1833 = _1818.xyz;\n        float _1838 = dot(_1833, world_pos) + _1818.w;\n        vec3 _1840 = _1823.xyz;\n        float _1845 = dot(_1840, world_pos) + _1823.w;\n        bool _1850 = abs(_1831) > 0.5;\n        bool _1858;\n        if (!_1850)\n        {\n            _1858 = abs(_1838) > 0.5;\n        }\n        else\n        {\n            _1858 = _1850;\n        }\n        bool _1866;\n        if (!_1858)\n        {\n            _1866 = abs(_1845) > 0.5;\n        }\n        else\n        {\n            _1866 = _1858;\n        }\n        if (_1866)\n        {\n            continue;\n        }\n        float _1881 = clamp(dot(geo_normal, normalize(_1840)) * _1798.z, 0.0, 1.0);\n        if (_1881 <= 0.0)\n        {\n            continue;\n        }\n        float _1901 = (clamp((0.5 - abs(_1845)) * 10.0, 0.0, 1.0) * _1881) * _1798.x;\n        vec2 _1909 = vec2(_1831 + 0.5, 0.5 - _1838);\n        vec2 _1919 = vec2(dot(_1826, _1715), dot(_1833, _1715));\n        vec2 _1929 = vec2(dot(_1826, _1718), dot(_1833, _1718));\n        int param_8 = _1793 + 5;\n        vec4 _1934 = fa_light_texel(param_8);\n        int param_9 = _1793 + 3;\n        vec4 _1939 = fa_light_texel(param_9);\n        int param_10 = _1793 + 4;\n        vec4 _1944 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1934.xyz;\n        bool _1954 = _1939.z > _1939.x;\n        if (_1954)\n        {\n            vec4 param_11 = _1939;\n            vec2 param_12 = _1909;\n            vec2 param_13 = _1743;\n            vec2 param_14 = _1919;\n            vec2 param_15 = _1929;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1753 > 0.5) && (_1753 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1980 = fa_dc_to_linear(param_16);\n                vec4 _7189 = tx;\n                _7189.x = _1980.x;\n                _7189.y = _1980.y;\n                _7189.z = _1980.z;\n                tx = _7189;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1901 * tex_a) * _1934.w, 0.0, 1.0)));\n        if (_1944.z > _1944.x)\n        {\n            vec4 param_17 = _1944;\n            vec2 param_18 = _1909;\n            vec2 param_19 = _1743;\n            vec2 param_20 = _1919;\n            vec2 param_21 = _1929;\n            vec4 _2024 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1753 > 1.5)\n            {\n                vec3 param_22 = _2024.xyz;\n                vec3 _2034 = fa_dc_to_srgb(param_22);\n                _2028 = _2034;\n            }\n            else\n            {\n                _2028 = _2024.xyz;\n            }\n            vec3 _2043 = (_2028 * 2.0) - vec3(1.0);\n            vec2 _2048 = _2043.xy * _1798.y;\n            vec3 _2070 = (normalize(_1826) * _2048.x) + (normalize(_1833) * _2048.y);\n            vec3 _2073 = normalize(normal);\n            normal = normalize(mix(_2073, normalize((_2073 * max(_2043.z, 0.0500000007450580596923828125)) + (_2070 - (_2073 * dot(_2073, _2070)))), vec3(clamp(_1901 * (_1954 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3430 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3430;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4042 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4047 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4042 > 0.0005000000237487256526947021484375)\n    {\n        if (_4047)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4042;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4042;\n        }\n    }\n    bool _4098 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4098)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4129 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4129)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4047 || _4098) || _4129)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3450 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3453 = _3450.x;\n    float _3455 = _3450.z;\n    vec2 e = vec2(_3453, _3455);\n    if (_3450.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3455)) * ((_3453 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3453)) * ((_3455 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _5674 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _5679 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _5684 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _5689 = fa_light_texel(param_3);\n    bool _5692 = _5689.z < 0.5;\n    bool _5700;\n    if (!_5692)\n    {\n        _5700 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _5700 = _5692;\n    }\n    if (_5700)\n    {\n        return vec3(0.0);\n    }\n    float _5707 = max(_5674.w, 9.9999997473787516355514526367188e-05);\n    vec3 _5710 = _5679.xyz;\n    vec3 _5714 = _5674.xyz;\n    vec3 _5718 = (fa_world_pos - _5714) / vec3(_5707);\n    vec3 _5727 = min(_5718 + vec3(0.5), (_5710 - vec3(0.5)) - _5718);\n    float _5736 = min(_5727.x, min(_5727.y, _5727.z));\n    if (!(_5736 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5751 = _5710 - vec3(1.0);\n    vec3 _5752 = clamp(_5718, vec3(0.0), _5751);\n    vec3 _5760 = min(floor(_5752), max(_5710 - vec3(2.0), vec3(0.0)));\n    vec3 _5764 = _5752 - _5760;\n    vec3 _5775 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _5707));\n    int _5780 = int(_5684.y + 0.5);\n    float _5785 = 0.3257350027561187744140625 * n.y;\n    float _5789 = 0.3257350027561187744140625 * n.z;\n    float _5793 = 0.3257350027561187744140625 * n.x;\n    float _5800 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _5807 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _5816 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _5823 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _5836 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _5843 = 8 + int(_5689.w);\n    float _5870;\n    float _5883;\n    float _5897;\n    for (int k = 0; k < _5843; k++)\n    {\n        float _5856 = float(k & 1);\n        float _5860 = float((k >> 1) & 1);\n        float _5864 = float((k >> 2) & 1);\n        if (_5856 > 0.5)\n        {\n            _5870 = _5764.x;\n        }\n        else\n        {\n            _5870 = 1.0 - _5764.x;\n        }\n        if (_5860 > 0.5)\n        {\n            _5883 = _5764.y;\n        }\n        else\n        {\n            _5883 = 1.0 - _5764.y;\n        }\n        if (_5864 > 0.5)\n        {\n            _5897 = _5764.z;\n        }\n        else\n        {\n            _5897 = 1.0 - _5764.z;\n        }\n        float _5907 = (_5870 * _5883) * _5897;\n        if (!(_5907 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5920 = min(_5760 + vec3(_5856, _5860, _5864), _5751);\n        int _5940 = int(((_5684.x + _5920.x) + (_5679.x * (_5920.y + (_5679.y * _5920.z)))) + 0.5);\n        vec2 _5955 = vec2(float(_5940 % _5780) * 10.0, 1024.0 + (float(_5940 / _5780) * 11.0));\n        vec2 param_4 = _5955 + vec2(9.5, 10.5);\n        vec4 _5963 = fa_gi_fetch(param_4);\n        bool _5966 = _5963.y < 0.5;\n        bool _5975;\n        if (!_5966)\n        {\n            _5975 = _5963.x > _5689.y;\n        }\n        else\n        {\n            _5975 = _5966;\n        }\n        if (_5975)\n        {\n            continue;\n        }\n        vec3 _5987 = _5775 - (_5714 + (_5920 * _5707));\n        float _5990 = length(_5987);\n        vec3 _5996 = _5987 / vec3(max(_5990, 9.9999997473787516355514526367188e-05));\n        float _6006 = max(9.9999997473787516355514526367188e-05, (dot(-_5996, n) + 1.0) * 0.5);\n        float w = _5907 * (_6006 * _6006);\n        vec3 param_5 = _5996;\n        vec2 param_6 = (_5955 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _6025 = fa_gi_fetch(param_6);\n        float _6032 = _5990 / max(_5684.z, 9.9999997473787516355514526367188e-05);\n        float _6035 = _6025.x;\n        if (_6032 > _6035)\n        {\n            float _6048 = max(_6025.y - (_6035 * _6035), 0.0);\n            float _6053 = _6032 - _6035;\n            float _6062 = _6048 / max(_6048 + (_6053 * _6053), 9.9999999600419720025001879548654e-13);\n            w *= ((_6062 * _6062) * _6062);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5955 + vec2(0.5, 10.5);\n        vec2 param_8 = _5955 + vec2(1.5, 10.5);\n        vec2 param_9 = _5955 + vec2(2.5, 10.5);\n        vec2 param_10 = _5955 + vec2(3.5, 10.5);\n        vec2 param_11 = _5955 + vec2(4.5, 10.5);\n        vec2 param_12 = _5955 + vec2(5.5, 10.5);\n        vec2 param_13 = _5955 + vec2(6.5, 10.5);\n        vec2 param_14 = _5955 + vec2(7.5, 10.5);\n        vec2 param_15 = _5955 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _5785)) + (fa_gi_fetch(param_9).xyz * _5789)) + (fa_gi_fetch(param_10).xyz * _5793)) + (fa_gi_fetch(param_11).xyz * _5800)) + (fa_gi_fetch(param_12).xyz * _5807)) + (fa_gi_fetch(param_13).xyz * _5816)) + (fa_gi_fetch(param_14).xyz * _5823)) + (fa_gi_fetch(param_15).xyz * _5836)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_5736 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6188;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6188 = _5689.x;\n    }\n    else\n    {\n        _6188 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_5684.w * _6188);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6212 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6217 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6222 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6222) && (k < 8); k++)\n    {\n        int param = _6217 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6212;\n        vec3 _6247 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6252 = param_3 * left;\n        acc += (_6247 * _6252);\n        left -= _6252;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6281 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6281;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4261 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4269 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4272 = int(_4261);\n    int _4275 = int(_4269);\n    float _4285 = _4269 - float(_4275);\n    int _4340 = (_4272 * 9) + _4275;\n    int _4360 = ((_4272 + 1) * 9) + _4275;\n    return mix(mix(_4336[_4340], _4336[_4340 + 1], _4285), mix(_4336[_4360], _4336[_4360 + 1], _4285), _4261 - float(_4272));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6960 = false;\n    float _6961 = 1.0;\n    float _6962 = 1.0;\n    float _6963 = 1.0;\n    float _6964 = 0.0;\n    float _6965 = 0.0;\n    float _6966 = 0.0;\n    float _6967 = 0.0;\n    float _6969 = 1.0;\n    bool _6970 = false;\n    vec3 _6971 = vec3(0.0);\n    float _6972 = 1.0;\n    float _6973 = 1.0;\n    float _6974 = 1.0;\n    float _6975 = 0.0;\n    float _6976 = 0.0;\n    vec3 _6977 = vec3(1.0, 0.0, 0.0);\n    vec3 _6978 = vec3(0.0, 0.0, 1.0);\n    float _6979 = 1.0;\n    float _6980 = 1.0;\n    float _4411 = clamp(s.specular, 0.0, 1.0);\n    float _4415 = clamp(s.ior, 1.0, 3.0);\n    bool _4420 = (_4411 != 1.0) || (_4415 != 1.5);\n    bool _4429;\n    if (!_4420)\n    {\n        _4429 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4429 = _4420;\n    }\n    if (_4429)\n    {\n        float _4437 = (_4415 - 1.0) / (_4415 + 1.0);\n        f0 = mix(min(vec3(_4437 * _4437) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4411, s.albedo, vec3(metallic));\n        _6961 = mix(_4411, 1.0, metallic);\n        _6960 = true;\n    }\n    float _4464 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4464 > 0.0)\n    {\n        float _4472 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6964 = _4464;\n        _6965 = _4472;\n        float _4479 = _4472 * _4472;\n        _6966 = _4479;\n        _6967 = _4479 * _4479;\n        float _4491 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6969 = _4491;\n        _6962 = 1.0 - (_4464 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4491, 0.0, 1.0), 5.0))));\n        _6960 = true;\n    }\n    vec3 _4510 = max(s.sheen_color, vec3(0.0));\n    float _4519 = max(_4510.x, max(_4510.y, _4510.z));\n    if (_4519 > 0.0)\n    {\n        float _4527 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6970 = true;\n        _6971 = _4510;\n        _6972 = _4527;\n        _6973 = _4527 * _4527;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4527;\n        float _4544 = fa_sheen_albedo(param, param_1);\n        _6975 = _4544;\n        _6974 = 1.0 - min(_4519 * _4544, 1.0);\n        _6960 = true;\n    }\n    _6963 = _6962 * _6974;\n    float _4563 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4563 != 0.0)\n    {\n        vec3 _4578 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4578;\n        if (dot(_4578, _4578) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4590 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4590.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4590.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4590.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4594 = t;\n        vec3 _4595 = normalize(_4594);\n        t = _4595;\n        vec3 _4620 = normalize((_4595 * cos(s.anisotropy_rotation)) + ((cross(n, _4595) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6977 = _4620;\n        _6978 = cross(n, _4620);\n        float _4630 = roughness * roughness;\n        float _4636 = mix(_4630, 1.0, _4563 * _4563);\n        bool _4638 = _4563 > 0.0;\n        _6979 = _4638 ? _4636 : _4630;\n        _6980 = _4638 ? _4630 : _4636;\n        _6976 = _4563;\n        _6960 = true;\n    }\n    return FaLayers(_6960, _6961, _6962, _6963, _6964, _6965, _6966, _6967, i.world_normal, _6969, _6970, _6971, _6972, _6973, _6974, _6975, _6976, _6977, _6978, _6979, _6980);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4193 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4196 = _4193.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4196 * _4196, exp2((-9.27999973297119140625) * ndv)) * _4196) + _4193.y)) + _4193.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3502;\n    if (lv == 0)\n    {\n        _3502 = 0.0;\n    }\n    else\n    {\n        _3502 = res + 2.0;\n    }\n    float _3512;\n    if (lv == 0)\n    {\n        _3512 = 0.0;\n    }\n    else\n    {\n        _3512 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3502, _3512)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3558;\n    if (res > 64.5)\n    {\n        _3558 = 5.0;\n    }\n    else\n    {\n        _3558 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3573 = clamp(rough, 0.0, 1.0) * (_3558 - 1.0);\n    int _3580 = int(min(floor(_3573), _3558 - 2.0));\n    float _3585 = _3573 - float(_3580);\n    vec3 param = d;\n    vec2 _3589 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3580;\n    vec2 param_4 = _3589;\n    vec3 _3599 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3585 < 0.00200000009499490261077880859375)\n    {\n        return _3599;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3580 + 1;\n    vec2 param_8 = _3589;\n    return mix(_3599, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3585));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3671 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3678 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3685 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3691 = dot(bx.xyz, d);\n    float _3695 = dot(by.xyz, d);\n    float _3699 = dot(bz.xyz, d);\n    float _3705;\n    if (_3691 > 9.9999999747524270787835121154785e-07)\n    {\n        _3705 = (1.0 - _3671) / _3691;\n    }\n    else\n    {\n        float _3719;\n        if (_3691 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3719 = ((-1.0) - _3671) / _3691;\n        }\n        else\n        {\n            _3719 = 1000000015047466219876688855040.0;\n        }\n        _3705 = _3719;\n    }\n    float tx = _3705;\n    float _3736;\n    if (_3695 > 9.9999999747524270787835121154785e-07)\n    {\n        _3736 = (1.0 - _3678) / _3695;\n    }\n    else\n    {\n        float _3749;\n        if (_3695 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3749 = ((-1.0) - _3678) / _3695;\n        }\n        else\n        {\n            _3749 = 1000000015047466219876688855040.0;\n        }\n        _3736 = _3749;\n    }\n    float ty = _3736;\n    float _3765;\n    if (_3699 > 9.9999999747524270787835121154785e-07)\n    {\n        _3765 = (1.0 - _3685) / _3699;\n    }\n    else\n    {\n        float _3778;\n        if (_3699 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3778 = ((-1.0) - _3685) / _3699;\n        }\n        else\n        {\n            _3778 = 1000000015047466219876688855040.0;\n        }\n        _3765 = _3778;\n    }\n    float _3790 = tx;\n    float _3793 = (_3790 > 0.0) ? _3790 : 1000000015047466219876688855040.0;\n    tx = _3793;\n    float _3794 = ty;\n    float _3797 = (_3794 > 0.0) ? _3794 : 1000000015047466219876688855040.0;\n    ty = _3797;\n    float _3807 = min(_3793, min(_3797, (_3765 > 0.0) ? _3765 : 1000000015047466219876688855040.0));\n    if (_3807 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3823 = (fa_world_pos + (d * _3807)) - posw.xyz;\n    vec3 _3828;\n    if (dot(_3823, _3823) > 1.0000000133514319600180897396058e-10)\n    {\n        _3828 = normalize(_3823);\n    }\n    else\n    {\n        _3828 = d;\n    }\n    return _3828;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3874 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3874 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3902 = rough * rough;\n            float _3933 = 0.60000002384185791015625 * _3902;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3902)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3933, 0.0500000007450580596923828125 + _3933, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3902 * 0.60000002384185791015625));\n        }\n        outc = base * _3874;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3992 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3992 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4024 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4024 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4671;\n        if (L.aniso >= 0.0)\n        {\n            _4671 = L.b;\n        }\n        else\n        {\n            _4671 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4671, v), _4671), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4707 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4707.x) + (vec3(L.f90) * _4707.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4765 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4765.x) + _4765.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4235 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4235.x) + vec3(_4235.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4794 = clamp(s.metallic, 0.0, 1.0);\n    float _4798 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4805 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4794));\n    vec3 f0 = _4805;\n    vec3 _4809 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4809;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4794;\n    float param_5 = _4798;\n    vec3 param_6 = _4805;\n    FaLayers _4826 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4826.on)\n    {\n        FaLayers param_7 = _4826;\n        vec3 param_8 = _4809;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4798;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4809;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4798;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5121;\n    if (fa_lm.z > 0.5)\n    {\n        _5121 = 0.0;\n    }\n    else\n    {\n        _5121 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5132 = _5121 < 1.0;\n    bool _5138;\n    if (_5132)\n    {\n        int param = li;\n        _5138 = fa_light_baked(param);\n    }\n    else\n    {\n        _5138 = _5132;\n    }\n    return _5138 ? _5121 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _676 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _689 = (c - (ru * hx)) - p;\n        vec3 _695 = ru * (2.0 * hx);\n        float _701 = max(dot(_695, _695), 9.9999999392252902907785028219223e-09);\n        float _705 = dot(_689, _695);\n        float t = clamp((-_705) / _701, 0.0, 1.0);\n        if (_676)\n        {\n            float _720 = dot(r, _695);\n            float _726 = _701 - (_720 * _720);\n            if (abs(_726) > (9.9999997473787516355514526367188e-06 * _701))\n            {\n                t = clamp(((dot(r, _689) * _720) - _705) / _726, 0.0, 1.0);\n            }\n        }\n        return (p + _689) + (_695 * t);\n    }\n    vec3 q = p;\n    float _758 = dot(r, axis);\n    bool _766;\n    if (_676)\n    {\n        _766 = abs(_758) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _766 = _676;\n    }\n    if (_766)\n    {\n        float _776 = dot(c - p, axis) / _758;\n        if (_776 > 0.0)\n        {\n            q = p + (r * _776);\n        }\n    }\n    vec3 _789 = q - c;\n    vec2 xy = vec2(dot(_789, ru), dot(_789, uu));\n    if (shape > 0.5)\n    {\n        float _804 = length(xy);\n        if (_804 > hx)\n        {\n            xy *= (hx / _804);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10)\n    {\n        _611 = atan(_600, _596) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _611 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_611 - floor(_611)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _446 = abs(d);\n    float _448 = _446.x;\n    float _450 = _446.y;\n    bool _451 = _448 >= _450;\n    bool _459;\n    if (_451)\n    {\n        _459 = _448 >= _446.z;\n    }\n    else\n    {\n        _459 = _451;\n    }\n    int _460;\n    if (_459)\n    {\n        _460 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _475;\n        if (_450 >= _446.z)\n        {\n            _475 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _475 = (d.z > 0.0) ? 4 : 5;\n        }\n        _460 = _475;\n    }\n    return _460;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _842 = fa_light_base(param);\n    bool _846 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _842;\n    vec4 _850 = fa_light_texel(param_1);\n    int param_2 = _842 + 1;\n    vec4 _855 = fa_light_texel(param_2);\n    float _858 = _855.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _870 = _846 && (_858 > 2.5);\n    fa_light_is_area = _870;\n    bool _872 = _858 < 0.5;\n    vec3 l;\n    if (_872)\n    {\n        l = normalize(_850.xyz);\n        if (_846)\n        {\n            int param_3 = _842 + 6;\n            vec4 _886 = fa_light_texel(param_3);\n            if (_886.z > 0.5)\n            {\n                int param_4 = _842 + 4;\n                vec4 _896 = fa_light_texel(param_4);\n                int param_5 = _842 + 5;\n                vec4 _901 = fa_light_texel(param_5);\n                vec2 param_6 = _886.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _896.xyz) * _896.w, (-dot(world_pos, _901.xyz)) * _901.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _931 = _850.xyz;\n        vec3 _933 = _931 - world_pos;\n        vec3 to_light = _933;\n        float _936 = length(_933);\n        float reach = _936;\n        bool front = true;\n        if (_870)\n        {\n            int param_8 = _842 + 7;\n            reach = max(_936 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _842 + 4;\n            vec4 _960 = fa_light_texel(param_9);\n            int param_10 = _842 + 5;\n            vec4 _965 = fa_light_texel(param_10);\n            int param_11 = _842 + 6;\n            vec4 _970 = fa_light_texel(param_11);\n            float _971 = _970.w;\n            int param_12 = _842 + 2;\n            vec3 _978 = normalize(fa_light_texel(param_12).xyz);\n            bool _980 = _971 > 1.5;\n            bool _988;\n            if (!_980)\n            {\n                _988 = dot(_978, to_light) < 0.0;\n            }\n            else\n            {\n                _988 = _980;\n            }\n            front = _988;\n            vec3 r = vec3(0.0);\n            vec3 _997 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1001 = dot(n, n) > 0.5;\n            bool _1009;\n            if (_1001)\n            {\n                _1009 = dot(_997, _997) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1009 = _1001;\n            }\n            if (_1009)\n            {\n                r = reflect(-normalize(_997), normalize(n));\n            }\n            vec3 param_13 = _931;\n            vec3 param_14 = _978;\n            vec3 param_15 = _960.xyz;\n            vec3 param_16 = _965.xyz;\n            float param_17 = _960.w;\n            float param_18 = _965.w;\n            float param_19 = _971;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1045 = length(to_light);\n        dist = _1045;\n        l = to_light / vec3(max(_1045, 9.9999997473787516355514526367188e-05));\n        float _1059 = reach / max(_850.w, 0.001000000047497451305389404296875);\n        float _1065 = clamp(1.0 - (_1059 * _1059), 0.0, 1.0);\n        float _1067;\n        if (front)\n        {\n            _1067 = _1065 * _1065;\n        }\n        else\n        {\n            _1067 = 0.0;\n        }\n        atten = _1067;\n        bool _1078 = _858 < 2.5;\n        if ((_858 > 1.5) && _1078)\n        {\n            int param_22 = _842 + 2;\n            vec4 _1086 = fa_light_texel(param_22);\n            float _1096 = _1086.w;\n            int param_23 = _842 + 3;\n            vec4 _1101 = fa_light_texel(param_23);\n            float _1102 = _1101.x;\n            float cos_inner = _1102;\n            if (_1102 > 1.5)\n            {\n                cos_inner = mix(_1096, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1096, cos_inner, dot(-l, normalize(_1086.xyz)));\n        }\n        if (_846 && (_858 < 1.5))\n        {\n            int param_24 = _842 + 6;\n            vec4 _1126 = fa_light_texel(param_24);\n            if (_1126.z > 0.5)\n            {\n                vec3 _1134 = -to_light;\n                int param_25 = _842 + 4;\n                int param_26 = _842 + 5;\n                vec3 _1148 = fa_light_texel(param_25).xyz;\n                vec3 _1152 = fa_light_texel(param_26).xyz;\n                vec3 _1161 = vec3(dot(_1134, _1148), dot(_1134, _1152), dot(_1134, cross(_1148, _1152)));\n                vec3 param_27 = _1161;\n                int _1165 = fa_cube_face(param_27);\n                int param_28 = _1165;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1192 = vec2(dot(_1161, cross(param_29, param_30)), dot(_1161, param_30)) / vec2(max(dot(_1161, param_29), 9.9999997473787516355514526367188e-05));\n                int _1196 = _1165 / 3;\n                vec2 param_31 = _1126.xy + (vec2(float(_1165 - (_1196 * 3)), float(_1196)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1192.x), 0.5 - (0.5 * _1192.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _842 + 7;\n            vec4 _1226 = fa_light_texel(param_33);\n            if (_1226.z > 0.5)\n            {\n                int param_34 = _842 + 2;\n                int param_35 = _842 + 4;\n                int param_36 = _842 + 5;\n                vec2 param_37 = _1226.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_846 && _1078)\n            {\n                int param_42 = _842 + 6;\n                vec4 _1273 = fa_light_texel(param_42);\n                int param_43 = _842 + 7;\n                vec4 _1278 = fa_light_texel(param_43);\n                bool _1281 = _1273.z > 0.5;\n                bool _1288;\n                if (!_1281)\n                {\n                    _1288 = _1278.z > 0.5;\n                }\n                else\n                {\n                    _1288 = _1281;\n                }\n                if (_1288)\n                {\n                    int param_44 = _842 + 2;\n                    vec4 _1295 = fa_light_texel(param_44);\n                    vec3 _1299 = normalize(_1295.xyz);\n                    int param_45 = _842 + 4;\n                    vec4 _1304 = fa_light_texel(param_45);\n                    int param_46 = _842 + 5;\n                    vec4 _1309 = fa_light_texel(param_46);\n                    if (_1281)\n                    {\n                        vec3 _1317 = -to_light;\n                        float _1324 = _1295.w;\n                        float _1340 = 0.5 / max(dot(_1317, _1299) * (sqrt(max(1.0 - (_1324 * _1324), 0.0)) / max(_1324, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1273.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1317, _1304.xyz) * _1340), 0.5 - (dot(_1317, _1309.xyz) * _1340));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1278.z > 0.5)\n                    {\n                        vec2 param_49 = _1278.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1299;\n                        vec3 param_52 = _1304.xyz;\n                        vec3 param_53 = _1309.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6948 = _855.xyz * atten;\n    if (_846)\n    {\n        _6948 *= fa_light_tint;\n    }\n    int _1408;\n    if (_872)\n    {\n        _1408 = 0;\n    }\n    else\n    {\n        _1408 = ((_858 > 1.5) && (_858 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6948, atten, 1.0, dist, _1408);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2197 = fa_shadow_depth(param, param_1);\n    float _2201;\n    if (conv.x < 0.5)\n    {\n        _2201 = _2197;\n    }\n    else\n    {\n        _2201 = (conv.y * conv.z) / (conv.z - (_2197 * (conv.z - conv.y)));\n    }\n    return _2201;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2247 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2253 = vec2(cos(_2247), sin(_2247));\n    vec2 dir = _2253;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2262;\n        if (k < 0.0)\n        {\n            _2262 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2262 = k;\n        }\n        float _2281 = clamp((_2262 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2300 = sqrt((float(i) + 0.5) * 0.0625) * _2281;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2300));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2314 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2314 < (zr - (_2300 * plane)))\n            {\n                sum += _2314;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2342 = sum / cnt;\n        float _2352;\n        if (k < 0.0)\n        {\n            _2352 = (-k) / max(_2342, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2352 = k;\n        }\n        radius = clamp(((max(zr - _2342, 0.0) * unit) * _2352) / texel_m, 1.5, 16.0);\n        dir = _2253;\n    }\n    float lit = 0.0;\n    int _2378 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2378; i_1++)\n    {\n        float _2397 = sqrt((float(i_1) + 0.5) / float(_2378)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2397));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2397 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2378);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2602 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2609;\n    if (!_2602)\n    {\n        _2609 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2609 = _2602;\n    }\n    if (_2609)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2622 = fa_light_texel(param);\n    float _2623 = _2622.x;\n    if (_2623 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2632 = int(_2623 + 0.5);\n    int param_1 = _2632;\n    vec4 _2636 = fa_light_texel(param_1);\n    int param_2 = _2632 + 1;\n    vec4 _2641 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2644 = _2636.y;\n    if (_2644 > 0.0)\n    {\n        float _2661 = 1.0 - smoothstep(0.75 * _2644, _2644, length(world - fa_shadows[27].xyz));\n        fade = _2661;\n        if (_2661 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2636.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2685 = (_2632 + 2) + (face * 6);\n    int param_4 = _2685;\n    int param_5 = _2685 + 1;\n    int param_6 = _2685 + 3;\n    vec4 _2699 = fa_light_texel(param_6);\n    int param_7 = _2685 + 4;\n    vec4 _2704 = fa_light_texel(param_7);\n    int param_8 = _2685 + 5;\n    vec4 _2709 = fa_light_texel(param_8);\n    float _2721 = _2709.x * max(dot(_2699, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2726 = clamp(dot(n, l), 0.0, 1.0);\n    float _2749 = clamp(dot(n, _2699.xyz), -1.0, 1.0);\n    float _2768 = min(sqrt(1.0 - (_2749 * _2749)) / max(abs(dot(n, world - lpos)) / max(dot(_2699, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2771 = _2641.y;\n    float _2773;\n    if (_2771 > 0.0)\n    {\n        _2773 = _2771;\n    }\n    else\n    {\n        _2773 = 1.5 * _2721;\n    }\n    vec4 _2793 = vec4(world + (n * (_2773 * sqrt(1.0 - (_2726 * _2726)))), 1.0);\n    float _2797 = dot(_2699, _2793);\n    float _2800 = _2709.y;\n    if (_2797 < _2800)\n    {\n        return 1.0;\n    }\n    vec2 _2815 = vec2(dot(fa_light_texel(param_4), _2793), dot(fa_light_texel(param_5), _2793)) / vec2(_2797);\n    float _2817 = _2815.x;\n    bool _2820 = _2817 < _2704.x;\n    bool _2829;\n    if (!_2820)\n    {\n        _2829 = _2817 > _2704.z;\n    }\n    else\n    {\n        _2829 = _2820;\n    }\n    bool _2838;\n    if (!_2829)\n    {\n        _2838 = _2815.y < _2704.y;\n    }\n    else\n    {\n        _2838 = _2829;\n    }\n    bool _2847;\n    if (!_2838)\n    {\n        _2847 = _2815.y > _2704.w;\n    }\n    else\n    {\n        _2847 = _2838;\n    }\n    if (_2847)\n    {\n        return 1.0;\n    }\n    float _2853 = _2641.x;\n    float _2855;\n    if (_2853 > 0.0)\n    {\n        _2855 = _2853;\n    }\n    else\n    {\n        _2855 = 1.5 * _2721;\n    }\n    vec2 param_9 = _2815;\n    vec4 param_10 = _2704;\n    float param_11 = _2797 - (_2855 * (1.0 + (0.5 * _2768)));\n    float param_12 = _2721;\n    float param_13 = 1.0;\n    float param_14 = _2709.z * 0.25;\n    float param_15 = (_2721 * min(_2768, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2800, _2709.z);\n    int param_17 = int(_2636.z + 0.5);\n    float param_18 = _2636.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2140;\n    if (i == 0)\n    {\n        _2140 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2156;\n        if (i == 1)\n        {\n            _2156 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2164;\n            if (i == 2)\n            {\n                _2164 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2164 = fa_shadows[24].w;\n            }\n            _2156 = _2164;\n        }\n        _2140 = _2156;\n    }\n    return _2140;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2443 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2448 = clamp(dot(n, l), 0.0, 1.0);\n    float _2454 = sqrt(1.0 - (_2448 * _2448));\n    float _2462 = min(_2454 / max(_2448, 0.20000000298023223876953125), 4.0);\n    float _2467;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2467 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2467 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2492 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2467 * _2454)), 1.0);\n    float _2499 = _2492.x;\n    bool _2502 = _2499 < fa_shadows[ci * 1 + 16].x;\n    bool _2511;\n    if (!_2502)\n    {\n        _2511 = _2499 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2511 = _2502;\n    }\n    bool _2520;\n    if (!_2511)\n    {\n        _2520 = _2492.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2520 = _2511;\n    }\n    bool _2529;\n    if (!_2520)\n    {\n        _2529 = _2492.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2529 = _2520;\n    }\n    bool _2536;\n    if (!_2529)\n    {\n        _2536 = _2492.z > 1.0;\n    }\n    else\n    {\n        _2536 = _2529;\n    }\n    if (_2536)\n    {\n        return -1.0;\n    }\n    float _2544;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2544 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2544 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2492.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2492.z - ((_2544 * (1.0 + (0.5 * _2462))) / _2443);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2443;\n    float param_5 = _2443 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2462, 3.0)) * 0.5) / _2443;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2922 = int(fa_shadows[25].x + 0.5);\n    if (_2922 < 1)\n    {\n        return 1.0;\n    }\n    float _2937 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2922 - 1;\n    if (_2937 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2949 = _2922 > 1;\n    bool _2956;\n    if (_2949)\n    {\n        _2956 = _2937 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2956 = _2949;\n    }\n    if (_2956)\n    {\n        ci = 1;\n    }\n    bool _2960 = _2922 > 2;\n    bool _2967;\n    if (_2960)\n    {\n        _2967 = _2937 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2967 = _2960;\n    }\n    if (_2967)\n    {\n        ci = 2;\n    }\n    bool _2971 = _2922 > 3;\n    bool _2978;\n    if (_2971)\n    {\n        _2978 = _2937 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2978 = _2971;\n    }\n    if (_2978)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2989 = min(_2922, 4);\n    float _3030;\n    for (int c = ci; c < _2989; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3009 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3009;\n            break;\n        }\n        if (_3009 < 0.0)\n        {\n            continue;\n        }\n        s = _3009;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3030 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3030 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3049 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3030, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2937 - (fa_shadow_split_at(param_7) - _3049)) / _3049, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3081;\n        if ((ci + 1) < _2922)\n        {\n            _3081 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3081 = 1.0;\n        }\n        s = mix(s, _3081, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3186 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3192;\n    if (_3186)\n    {\n        _3192 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3192 = _3186;\n    }\n    if (_3192)\n    {\n        vec4 _3202 = vec4(fa_world_pos, 1.0);\n        float _3208 = dot(fa_mesh_fs_params[28], _3202);\n        if (_3208 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3227 = vec2(dot(fa_mesh_fs_params[26], _3202), dot(fa_mesh_fs_params[27], _3202)) / vec2(_3208);\n            float _3232 = (_3227.x * 0.5) + 0.5;\n            float _3236;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3236 = (_3227.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3236 = 0.5 - (_3227.y * 0.5);\n            }\n            bool _3252 = _3232 >= 0.0;\n            bool _3258;\n            if (_3252)\n            {\n                _3258 = _3232 < 1.0;\n            }\n            else\n            {\n                _3258 = _3252;\n            }\n            bool _3264;\n            if (_3258)\n            {\n                _3264 = _3236 >= 0.0;\n            }\n            else\n            {\n                _3264 = _3258;\n            }\n            bool _3270;\n            if (_3264)\n            {\n                _3270 = _3236 < 1.0;\n            }\n            else\n            {\n                _3270 = _3264;\n            }\n            if (_3270)\n            {\n                vec4 _3296 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3232, _3236) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                float _3306 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n                bool _3309 = _3296.w > 0.5;\n                bool _3323;\n                if (_3309)\n                {\n                    _3323 = abs(_3306 - _3296.x) <= ((0.00200000009499490261077880859375 * _3306) + 0.00999999977648258209228515625);\n                }\n                else\n                {\n                    _3323 = _3309;\n                }\n                if (_3323)\n                {\n                    return _3296.y;\n                }\n            }\n        }\n    }\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4865 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4872;\n    if (!_4865)\n    {\n        _4872 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4872 = _4865;\n    }\n    if (_4872)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4885 = fa_light_texel(param);\n    float _4886 = _4885.y;\n    float len = _4886;\n    if (_4886 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4898 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4907 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4898);\n    if (_4907 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4913 = len;\n    float _4916 = min(_4913, 0.89999997615814208984375 * dist);\n    len = _4916;\n    float _4921 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4898);\n    float _4926 = _4921 + (0.5 * _4916);\n    vec3 _4932 = world + (gn * _4921);\n    float _4934 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4995;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4949 = (float(k) + _4934) * 0.083333335816860198974609375;\n        vec3 _4957 = _4932 + (l * (_4949 * len));\n        vec4 _4963 = vec4(_4957, 1.0);\n        float _4968 = dot(fa_mesh_fs_params[28], _4963);\n        if (_4968 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4986 = vec2(dot(fa_mesh_fs_params[26], _4963), dot(fa_mesh_fs_params[27], _4963)) / vec2(_4968);\n        float _4990 = _4986.x * 0.5;\n        float _4991 = _4990 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4995 = (_4986.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4995 = 0.5 - (_4986.y * 0.5);\n        }\n        bool _5011 = _4991 < 0.0;\n        bool _5018;\n        if (!_5011)\n        {\n            _5018 = _4991 >= 1.0;\n        }\n        else\n        {\n            _5018 = _5011;\n        }\n        bool _5025;\n        if (!_5018)\n        {\n            _5025 = _4995 < 0.0;\n        }\n        else\n        {\n            _5025 = _5018;\n        }\n        bool _5032;\n        if (!_5025)\n        {\n            _5032 = _4995 >= 1.0;\n        }\n        else\n        {\n            _5032 = _5025;\n        }\n        if (_5032)\n        {\n            break;\n        }\n        vec4 _5056 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4991, _4995) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5056.w < 0.5)\n        {\n            continue;\n        }\n        float _5074 = (dot(fa_mesh_fs_params[29].xyz, _4957) + fa_mesh_fs_params[29].w) - _5056.x;\n        if ((_5074 > _4921) && (_5074 < _4926))\n        {\n            occ = max(occ, (1.0 - (_4949 * _4949)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4991, 0.5 - _4990), min(_4995, 1.0 - _4995))));\n        }\n    }\n    return 1.0 - (occ * _4907);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5177 = fa_baked_keep(param);\n    if (_5177 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5203 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7081 = _5203.color;\n    float _7082 = _5203.attenuation;\n    float _7083 = _5203.shadow;\n    bool _5206 = _5203.type == 0;\n    if (_5206 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5203.direction;\n        float _5217 = fa_shadow_factor(param_5, param_6);\n        _7083 = _5217;\n        _7081 *= _5217;\n    }\n    else\n    {\n        bool _5228 = _5203.type != 0;\n        bool _5234;\n        if (_5228)\n        {\n            _5234 = _7082 > 0.0;\n        }\n        else\n        {\n            _5234 = _5228;\n        }\n        if (_5234)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5203.direction;\n            float _5253 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7083 = _5253;\n            _7081 *= _5253;\n        }\n    }\n    bool _5263 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5269;\n    if (_5263)\n    {\n        _5269 = _7082 > 0.0;\n    }\n    else\n    {\n        _5269 = _5263;\n    }\n    if (_5269)\n    {\n        float _5276;\n        if (_5206)\n        {\n            _5276 = 1000000000.0;\n        }\n        else\n        {\n            _5276 = _5203._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5203.direction;\n        float param_18 = _5276;\n        float _5294 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7083 *= _5294;\n        _7081 *= _5294;\n    }\n    float _5307 = _7082;\n    float _5308 = _5307 * _5177;\n    _7082 = _5308;\n    vec3 _5312 = _7081;\n    vec3 _5313 = _5312 * _5177;\n    _7081 = _5313;\n    return LightSample(_5203.direction, _5313, _5308, _7083, _5203._distance, _5203.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3109 = int(fa_shadows[25].x + 0.5);\n    float _3119 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3124 = _3109 > 0;\n    bool _3133;\n    if (_3124)\n    {\n        int param = _3109 - 1;\n        _3133 = _3119 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3133 = _3124;\n    }\n    if (_3133)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3139 = _3109 > 1;\n        bool _3146;\n        if (_3139)\n        {\n            _3146 = _3119 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3146 = _3139;\n        }\n        if (_3146)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3152 = _3109 > 2;\n        bool _3159;\n        if (_3152)\n        {\n            _3159 = _3119 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3159 = _3152;\n        }\n        if (_3159)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3165 = _3109 > 3;\n        bool _3172;\n        if (_3165)\n        {\n            _3172 = _3119 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3172 = _3165;\n        }\n        if (_3172)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6766 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6766 = -_6766;\n    }\n    vec3 _6389 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6766, fa_world_tangent, fa_uv, fa_vertex_color, _6389, gl_FrontFacing);\n    Surface _6397 = fa_standard_surface(param_1);\n    vec3 _6805 = _6397.albedo;\n    float _6806 = _6397.alpha;\n    vec3 _6807 = _6397.normal;\n    float _6808 = _6397.metallic;\n    float _6809 = _6397.roughness;\n    float _6810 = _6397.occlusion;\n    vec3 _6811 = _6397.emission;\n    float _6812 = _6397.clearcoat;\n    float _6813 = _6397.clearcoat_roughness;\n    vec3 _6814 = _6397.sheen_color;\n    float _6815 = _6397.sheen_roughness;\n    float _6816 = _6397.anisotropy;\n    float _6817 = _6397.anisotropy_rotation;\n    float _6818 = _6397.specular;\n    float _6819 = _6397.ior;\n    vec3 _6820 = _6397.specular_color;\n    float _6821 = _6397.transmission;\n    float _6822 = _6397.thickness;\n    vec3 _6823 = _6397.attenuation_color;\n    float _6824 = _6397.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6766, fa_world_tangent, fa_uv, fa_vertex_color, _6389, gl_FrontFacing);\n    Surface param_3 = _6397;\n    surface(param_2, param_3);\n    _6805 = param_3.albedo;\n    _6806 = param_3.alpha;\n    _6807 = param_3.normal;\n    _6808 = param_3.metallic;\n    _6809 = param_3.roughness;\n    _6810 = param_3.occlusion;\n    _6811 = param_3.emission;\n    _6812 = param_3.clearcoat;\n    _6813 = param_3.clearcoat_roughness;\n    _6814 = param_3.sheen_color;\n    _6815 = param_3.sheen_roughness;\n    _6816 = param_3.anisotropy;\n    _6817 = param_3.anisotropy_rotation;\n    _6818 = param_3.specular;\n    _6819 = param_3.ior;\n    _6820 = param_3.specular_color;\n    _6821 = param_3.transmission;\n    _6822 = param_3.thickness;\n    _6823 = param_3.attenuation_color;\n    _6824 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6766;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6805 = param_6;\n    _6807 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6805;\n    }\n    else\n    {\n        vec3 _6436 = _6807;\n        vec3 _6437 = normalize(_6436);\n        _6807 = _6437;\n        vec3 param_8 = _6437;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _6766, fa_world_tangent, fa_uv, fa_vertex_color, _6389, gl_FrontFacing);\n        Surface param_10 = Surface(_6805, _6806, _6807, _6808, _6809, _6810, _6811, _6812, _6813, _6814, _6815, _6816, _6817, _6818, _6819, _6820, _6821, _6822, _6823, _6824);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6456 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6456; ln++)\n        {\n            int param_12 = ln;\n            int _6469 = fa_cl_light(param_12);\n            int param_13 = _6469;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6469;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _6766;\n            LightSample _6485 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _6766, fa_world_tangent, fa_uv, fa_vertex_color, _6389, gl_FrontFacing);\n            Surface param_18 = Surface(_6805, _6806, _6807, _6808, _6809, _6810, _6811, _6812, _6813, _6814, _6815, _6816, _6817, _6818, _6819, _6820, _6821, _6822, _6823, _6824);\n            LightSample param_19 = _6485;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6500 = result;\n    vec3 _6501 = _6500 + _6811;\n    result = _6501;\n    vec3 param_20 = _6501;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6510 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6517;\n    if (!_6510)\n    {\n        _6517 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6517 = _6510;\n    }\n    if (_6517)\n    {\n        vec3 _6526 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6532 = dot(_6526, fa_mesh_fs_params[9].xyz);\n        bool _6536 = fa_mesh_fs_params[9].w > 0.5;\n        float _6537;\n        if (_6536)\n        {\n            _6537 = _6532;\n        }\n        else\n        {\n            _6537 = length(_6526);\n        }\n        float _6549 = _6537 - fa_mesh_fs_params[8].x;\n        if (_6549 > 0.0)\n        {\n            float _6558 = fa_mesh_fs_params[7].w * _6549;\n            float tau = _6558 * _6558;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6574;\n                if (_6536)\n                {\n                    _6574 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6532);\n                }\n                else\n                {\n                    _6574 = fa_mesh_fs_params[0].y;\n                }\n                float _6595 = mix(_6574, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6537, 0.0, 1.0));\n                float _6599 = fa_world_pos.y - _6595;\n                float _6604 = _6595 - fa_mesh_fs_params[8].z;\n                float _6609 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6612 = _6604 <= 0.0;\n                bool _6613 = !_6612;\n                bool _6619;\n                if (_6613)\n                {\n                    _6619 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6619 = _6612;\n                }\n                float _6620;\n                if (_6619)\n                {\n                    _6620 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6620 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6604, 80.0));\n                }\n                bool _6647;\n                if (_6613)\n                {\n                    _6647 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6647 = _6612;\n                }\n                float _6648;\n                if (_6647)\n                {\n                    _6648 = fa_mesh_fs_params[8].y * _6604;\n                }\n                else\n                {\n                    _6648 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6604, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6673 = _6609 <= 0.0;\n                bool _6680;\n                if (!_6673)\n                {\n                    _6680 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6680 = _6673;\n                }\n                float _6681;\n                if (_6680)\n                {\n                    _6681 = fa_mesh_fs_params[8].y * _6609;\n                }\n                else\n                {\n                    _6681 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6609, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6708;\n                if (abs(_6599) < 0.001000000047497451305389404296875)\n                {\n                    _6708 = _6620;\n                }\n                else\n                {\n                    _6708 = (_6681 - _6648) / _6599;\n                }\n                tau += (_6549 * max(_6708, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6806);\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_131",
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
            "inst_name": "_498",
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
            "inst_name": "_2150",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4336[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1426 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1433;\n    if (!_1426)\n    {\n        _1433 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1433 = _1426;\n    }\n    bool _1441;\n    if (!_1433)\n    {\n        _1441 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1441 = _1433;\n    }\n    bool _1448;\n    if (!_1441)\n    {\n        _1448 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1448 = _1441;\n    }\n    bool _1455;\n    if (!_1448)\n    {\n        _1455 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1455 = _1448;\n    }\n    if (_1455)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1465 = vec4(world_pos, 1.0);\n    float _1471 = dot(fa_mesh_fs_params[16], _1465);\n    if (!(_1471 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1493 = vec2(dot(fa_mesh_fs_params[14], _1465), dot(fa_mesh_fs_params[15], _1465)) / vec2(_1471);\n    int _1497 = int(fa_mesh_fs_params[18].x);\n    int _1501 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1501) + clamp(int(floor(((_1493.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1501 - 1)) * _1497)) + clamp(int(floor(((_1493.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1497 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1577 = fa_cluster_texel(param);\n    return ivec2(int(_1577.x), int(_1577.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5151 = fa_cluster_lookup(param);\n    fa_cl_slot = _5151.x;\n    fa_cl_local = _5151.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5363 = fa_linear_to_srgb(param);\n        c = _5363;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5371 = fa_srgb_to_linear(param_1);\n            c = _5371;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _380;\n    if (i.front_facing)\n    {\n        _380 = i.world_normal;\n    }\n    else\n    {\n        _380 = -i.world_normal;\n    }\n    vec3 _404 = normalize(i.world_tangent.xyz - (_380 * dot(_380, i.world_tangent.xyz)));\n    vec3 _431 = normalize(((_404 * m.x) + ((cross(_380, _404) * i.world_tangent.w) * m.y)) + (_380 * m.z));\n    vec3 _434;\n    if (i.front_facing)\n    {\n        _434 = _431;\n    }\n    else\n    {\n        _434 = -_431;\n    }\n    return _434;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5403 = fa_tex_fix(param_2, param_3);\n    vec4 _7305 = base_t;\n    _7305.x = _5403.x;\n    _7305.y = _5403.y;\n    _7305.z = _5403.z;\n    base_t = _7305;\n    vec4 _5417 = (_7305 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7101 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5451 = fa_tex_fix(param_6, param_7);\n        vec3 _5454 = (_5451 * 2.0) - vec3(1.0);\n        vec2 _5459 = _5454.xy * fa_mesh_fs_params[6].x;\n        vec3 _7313 = _5454;\n        _7313.x = _5459.x;\n        _7313.y = _5459.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7313;\n        _7101 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5489 = fa_tex_fix(param_12, param_13);\n    vec4 _7316 = mrt;\n    _7316.x = _5489.x;\n    _7316.y = _5489.y;\n    _7316.z = _5489.z;\n    mrt = _7316;\n    vec4 _5519 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5519.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5530 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5562 = fa_tex_fix(param_20, param_21);\n    float _7106 = fa_mesh_fs_params[20].x;\n    float _7107 = fa_mesh_fs_params[20].y;\n    float _7110 = fa_mesh_fs_params[20].z;\n    float _7109 = fa_mesh_fs_params[21].w;\n    float _7112 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7106 *= _5530.y;\n            _7107 *= _5530.z;\n            _7109 *= _5519.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7110 *= mrt.x;\n            _7112 *= mrt.w;\n        }\n    }\n    return Surface(_5417.xyz, _5417.w, _7101, clamp(fa_mesh_fs_params[5].x * _5489.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5489.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5530.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5562), _7106, _7107, fa_mesh_fs_params[21].xyz, _7109, _7110, fa_mesh_fs_params[20].w, _7112, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1657 = rect.zw - rect.xy;\n    vec2 _1661 = _1657 * atlas;\n    vec2 _1665 = ddx * _1661;\n    vec2 _1669 = ddy * _1661;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1657), clamp(0.5 * log2(max(max(dot(_1665, _1665), dot(_1669, _1669)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1702 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1709;\n    if (!_1702)\n    {\n        _1709 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1709 = _1702;\n    }\n    if (_1709)\n    {\n        return;\n    }\n    vec3 _1715 = dFdx(world_pos);\n    vec3 _1718 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1722 = fa_cluster_texel(param);\n    int _1726 = int(_1722.w);\n    if (_1726 < 1)\n    {\n        return;\n    }\n    int _1736 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1736;\n    vec4 _1740 = fa_light_texel(param_1);\n    vec2 _1743 = _1740.yz;\n    int _1747 = int(_1740.w);\n    int param_2 = _1736 + 1;\n    vec4 _1752 = fa_light_texel(param_2);\n    float _1753 = _1752.x;\n    int _1759 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1763 = int(_1722.z);\n    vec3 _2028;\n    for (int k = 0; k < _1726; k++)\n    {\n        int _1776 = _1763 + k;\n        int param_3 = _1747 + (_1776 >> 2);\n        int _1793 = (_1736 + 2) + (int(fa_light_texel(param_3)[_1776 & 3]) * 7);\n        int param_4 = _1793 + 6;\n        vec4 _1798 = fa_light_texel(param_4);\n        if (((int(_1798.w + 0.5) >> _1759) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1793;\n        vec4 _1813 = fa_light_texel(param_5);\n        int param_6 = _1793 + 1;\n        vec4 _1818 = fa_light_texel(param_6);\n        int param_7 = _1793 + 2;\n        vec4 _1823 = fa_light_texel(param_7);\n        vec3 _1826 = _1813.xyz;\n        float _1831 = dot(_1826, world_pos) + _1813.w;\n        vec3 _1833 = _1818.xyz;\n        float _1838 = dot(_1833, world_pos) + _1818.w;\n        vec3 _1840 = _1823.xyz;\n        float _1845 = dot(_1840, world_pos) + _1823.w;\n        bool _1850 = abs(_1831) > 0.5;\n        bool _1858;\n        if (!_1850)\n        {\n            _1858 = abs(_1838) > 0.5;\n        }\n        else\n        {\n            _1858 = _1850;\n        }\n        bool _1866;\n        if (!_1858)\n        {\n            _1866 = abs(_1845) > 0.5;\n        }\n        else\n        {\n            _1866 = _1858;\n        }\n        if (_1866)\n        {\n            continue;\n        }\n        float _1881 = clamp(dot(geo_normal, normalize(_1840)) * _1798.z, 0.0, 1.0);\n        if (_1881 <= 0.0)\n        {\n            continue;\n        }\n        float _1901 = (clamp((0.5 - abs(_1845)) * 10.0, 0.0, 1.0) * _1881) * _1798.x;\n        vec2 _1909 = vec2(_1831 + 0.5, 0.5 - _1838);\n        vec2 _1919 = vec2(dot(_1826, _1715), dot(_1833, _1715));\n        vec2 _1929 = vec2(dot(_1826, _1718), dot(_1833, _1718));\n        int param_8 = _1793 + 5;\n        vec4 _1934 = fa_light_texel(param_8);\n        int param_9 = _1793 + 3;\n        vec4 _1939 = fa_light_texel(param_9);\n        int param_10 = _1793 + 4;\n        vec4 _1944 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1934.xyz;\n        bool _1954 = _1939.z > _1939.x;\n        if (_1954)\n        {\n            vec4 param_11 = _1939;\n            vec2 param_12 = _1909;\n            vec2 param_13 = _1743;\n            vec2 param_14 = _1919;\n            vec2 param_15 = _1929;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1753 > 0.5) && (_1753 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1980 = fa_dc_to_linear(param_16);\n                vec4 _7189 = tx;\n                _7189.x = _1980.x;\n                _7189.y = _1980.y;\n                _7189.z = _1980.z;\n                tx = _7189;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1901 * tex_a) * _1934.w, 0.0, 1.0)));\n        if (_1944.z > _1944.x)\n        {\n            vec4 param_17 = _1944;\n            vec2 param_18 = _1909;\n            vec2 param_19 = _1743;\n            vec2 param_20 = _1919;\n            vec2 param_21 = _1929;\n            vec4 _2024 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1753 > 1.5)\n            {\n                vec3 param_22 = _2024.xyz;\n                vec3 _2034 = fa_dc_to_srgb(param_22);\n                _2028 = _2034;\n            }\n            else\n            {\n                _2028 = _2024.xyz;\n            }\n            vec3 _2043 = (_2028 * 2.0) - vec3(1.0);\n            vec2 _2048 = _2043.xy * _1798.y;\n            vec3 _2070 = (normalize(_1826) * _2048.x) + (normalize(_1833) * _2048.y);\n            vec3 _2073 = normalize(normal);\n            normal = normalize(mix(_2073, normalize((_2073 * max(_2043.z, 0.0500000007450580596923828125)) + (_2070 - (_2073 * dot(_2073, _2070)))), vec3(clamp(_1901 * (_1954 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3430 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3430;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _4042 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _4047 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_4042 > 0.0005000000237487256526947021484375)\n    {\n        if (_4047)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _4042;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _4042;\n        }\n    }\n    bool _4098 = fa_mesh_fs_params[42].w > 0.0;\n    if (_4098)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4129 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4129)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_4047 || _4098) || _4129)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3450 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3453 = _3450.x;\n    float _3455 = _3450.z;\n    vec2 e = vec2(_3453, _3455);\n    if (_3450.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3455)) * ((_3453 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3453)) * ((_3455 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _5674 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _5679 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _5684 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _5689 = fa_light_texel(param_3);\n    bool _5692 = _5689.z < 0.5;\n    bool _5700;\n    if (!_5692)\n    {\n        _5700 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _5700 = _5692;\n    }\n    if (_5700)\n    {\n        return vec3(0.0);\n    }\n    float _5707 = max(_5674.w, 9.9999997473787516355514526367188e-05);\n    vec3 _5710 = _5679.xyz;\n    vec3 _5714 = _5674.xyz;\n    vec3 _5718 = (fa_world_pos - _5714) / vec3(_5707);\n    vec3 _5727 = min(_5718 + vec3(0.5), (_5710 - vec3(0.5)) - _5718);\n    float _5736 = min(_5727.x, min(_5727.y, _5727.z));\n    if (!(_5736 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5751 = _5710 - vec3(1.0);\n    vec3 _5752 = clamp(_5718, vec3(0.0), _5751);\n    vec3 _5760 = min(floor(_5752), max(_5710 - vec3(2.0), vec3(0.0)));\n    vec3 _5764 = _5752 - _5760;\n    vec3 _5775 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _5707));\n    int _5780 = int(_5684.y + 0.5);\n    float _5785 = 0.3257350027561187744140625 * n.y;\n    float _5789 = 0.3257350027561187744140625 * n.z;\n    float _5793 = 0.3257350027561187744140625 * n.x;\n    float _5800 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _5807 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _5816 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _5823 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _5836 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _5843 = 8 + int(_5689.w);\n    float _5870;\n    float _5883;\n    float _5897;\n    for (int k = 0; k < _5843; k++)\n    {\n        float _5856 = float(k & 1);\n        float _5860 = float((k >> 1) & 1);\n        float _5864 = float((k >> 2) & 1);\n        if (_5856 > 0.5)\n        {\n            _5870 = _5764.x;\n        }\n        else\n        {\n            _5870 = 1.0 - _5764.x;\n        }\n        if (_5860 > 0.5)\n        {\n            _5883 = _5764.y;\n        }\n        else\n        {\n            _5883 = 1.0 - _5764.y;\n        }\n        if (_5864 > 0.5)\n        {\n            _5897 = _5764.z;\n        }\n        else\n        {\n            _5897 = 1.0 - _5764.z;\n        }\n        float _5907 = (_5870 * _5883) * _5897;\n        if (!(_5907 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5920 = min(_5760 + vec3(_5856, _5860, _5864), _5751);\n        int _5940 = int(((_5684.x + _5920.x) + (_5679.x * (_5920.y + (_5679.y * _5920.z)))) + 0.5);\n        vec2 _5955 = vec2(float(_5940 % _5780) * 10.0, 1024.0 + (float(_5940 / _5780) * 11.0));\n        vec2 param_4 = _5955 + vec2(9.5, 10.5);\n        vec4 _5963 = fa_gi_fetch(param_4);\n        bool _5966 = _5963.y < 0.5;\n        bool _5975;\n        if (!_5966)\n        {\n            _5975 = _5963.x > _5689.y;\n        }\n        else\n        {\n            _5975 = _5966;\n        }\n        if (_5975)\n        {\n            continue;\n        }\n        vec3 _5987 = _5775 - (_5714 + (_5920 * _5707));\n        float _5990 = length(_5987);\n        vec3 _5996 = _5987 / vec3(max(_5990, 9.9999997473787516355514526367188e-05));\n        float _6006 = max(9.9999997473787516355514526367188e-05, (dot(-_5996, n) + 1.0) * 0.5);\n        float w = _5907 * (_6006 * _6006);\n        vec3 param_5 = _5996;\n        vec2 param_6 = (_5955 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _6025 = fa_gi_fetch(param_6);\n        float _6032 = _5990 / max(_5684.z, 9.9999997473787516355514526367188e-05);\n        float _6035 = _6025.x;\n        if (_6032 > _6035)\n        {\n            float _6048 = max(_6025.y - (_6035 * _6035), 0.0);\n            float _6053 = _6032 - _6035;\n            float _6062 = _6048 / max(_6048 + (_6053 * _6053), 9.9999999600419720025001879548654e-13);\n            w *= ((_6062 * _6062) * _6062);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5955 + vec2(0.5, 10.5);\n        vec2 param_8 = _5955 + vec2(1.5, 10.5);\n        vec2 param_9 = _5955 + vec2(2.5, 10.5);\n        vec2 param_10 = _5955 + vec2(3.5, 10.5);\n        vec2 param_11 = _5955 + vec2(4.5, 10.5);\n        vec2 param_12 = _5955 + vec2(5.5, 10.5);\n        vec2 param_13 = _5955 + vec2(6.5, 10.5);\n        vec2 param_14 = _5955 + vec2(7.5, 10.5);\n        vec2 param_15 = _5955 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _5785)) + (fa_gi_fetch(param_9).xyz * _5789)) + (fa_gi_fetch(param_10).xyz * _5793)) + (fa_gi_fetch(param_11).xyz * _5800)) + (fa_gi_fetch(param_12).xyz * _5807)) + (fa_gi_fetch(param_13).xyz * _5816)) + (fa_gi_fetch(param_14).xyz * _5823)) + (fa_gi_fetch(param_15).xyz * _5836)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_5736 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6188;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6188 = _5689.x;\n    }\n    else\n    {\n        _6188 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_5684.w * _6188);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6212 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6217 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6222 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6222) && (k < 8); k++)\n    {\n        int param = _6217 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6212;\n        vec3 _6247 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6252 = param_3 * left;\n        acc += (_6247 * _6252);\n        left -= _6252;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6281 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6281;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4261 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4269 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4272 = int(_4261);\n    int _4275 = int(_4269);\n    float _4285 = _4269 - float(_4275);\n    int _4340 = (_4272 * 9) + _4275;\n    int _4360 = ((_4272 + 1) * 9) + _4275;\n    return mix(mix(_4336[_4340], _4336[_4340 + 1], _4285), mix(_4336[_4360], _4336[_4360 + 1], _4285), _4261 - float(_4272));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6960 = false;\n    float _6961 = 1.0;\n    float _6962 = 1.0;\n    float _6963 = 1.0;\n    float _6964 = 0.0;\n    float _6965 = 0.0;\n    float _6966 = 0.0;\n    float _6967 = 0.0;\n    float _6969 = 1.0;\n    bool _6970 = false;\n    vec3 _6971 = vec3(0.0);\n    float _6972 = 1.0;\n    float _6973 = 1.0;\n    float _6974 = 1.0;\n    float _6975 = 0.0;\n    float _6976 = 0.0;\n    vec3 _6977 = vec3(1.0, 0.0, 0.0);\n    vec3 _6978 = vec3(0.0, 0.0, 1.0);\n    float _6979 = 1.0;\n    float _6980 = 1.0;\n    float _4411 = clamp(s.specular, 0.0, 1.0);\n    float _4415 = clamp(s.ior, 1.0, 3.0);\n    bool _4420 = (_4411 != 1.0) || (_4415 != 1.5);\n    bool _4429;\n    if (!_4420)\n    {\n        _4429 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4429 = _4420;\n    }\n    if (_4429)\n    {\n        float _4437 = (_4415 - 1.0) / (_4415 + 1.0);\n        f0 = mix(min(vec3(_4437 * _4437) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4411, s.albedo, vec3(metallic));\n        _6961 = mix(_4411, 1.0, metallic);\n        _6960 = true;\n    }\n    float _4464 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4464 > 0.0)\n    {\n        float _4472 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6964 = _4464;\n        _6965 = _4472;\n        float _4479 = _4472 * _4472;\n        _6966 = _4479;\n        _6967 = _4479 * _4479;\n        float _4491 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6969 = _4491;\n        _6962 = 1.0 - (_4464 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4491, 0.0, 1.0), 5.0))));\n        _6960 = true;\n    }\n    vec3 _4510 = max(s.sheen_color, vec3(0.0));\n    float _4519 = max(_4510.x, max(_4510.y, _4510.z));\n    if (_4519 > 0.0)\n    {\n        float _4527 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6970 = true;\n        _6971 = _4510;\n        _6972 = _4527;\n        _6973 = _4527 * _4527;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4527;\n        float _4544 = fa_sheen_albedo(param, param_1);\n        _6975 = _4544;\n        _6974 = 1.0 - min(_4519 * _4544, 1.0);\n        _6960 = true;\n    }\n    _6963 = _6962 * _6974;\n    float _4563 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4563 != 0.0)\n    {\n        vec3 _4578 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4578;\n        if (dot(_4578, _4578) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4590 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4590.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4590.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4590.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4594 = t;\n        vec3 _4595 = normalize(_4594);\n        t = _4595;\n        vec3 _4620 = normalize((_4595 * cos(s.anisotropy_rotation)) + ((cross(n, _4595) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6977 = _4620;\n        _6978 = cross(n, _4620);\n        float _4630 = roughness * roughness;\n        float _4636 = mix(_4630, 1.0, _4563 * _4563);\n        bool _4638 = _4563 > 0.0;\n        _6979 = _4638 ? _4636 : _4630;\n        _6980 = _4638 ? _4630 : _4636;\n        _6976 = _4563;\n        _6960 = true;\n    }\n    return FaLayers(_6960, _6961, _6962, _6963, _6964, _6965, _6966, _6967, i.world_normal, _6969, _6970, _6971, _6972, _6973, _6974, _6975, _6976, _6977, _6978, _6979, _6980);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4193 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4196 = _4193.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4196 * _4196, exp2((-9.27999973297119140625) * ndv)) * _4196) + _4193.y)) + _4193.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3502;\n    if (lv == 0)\n    {\n        _3502 = 0.0;\n    }\n    else\n    {\n        _3502 = res + 2.0;\n    }\n    float _3512;\n    if (lv == 0)\n    {\n        _3512 = 0.0;\n    }\n    else\n    {\n        _3512 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3502, _3512)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3558;\n    if (res > 64.5)\n    {\n        _3558 = 5.0;\n    }\n    else\n    {\n        _3558 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3573 = clamp(rough, 0.0, 1.0) * (_3558 - 1.0);\n    int _3580 = int(min(floor(_3573), _3558 - 2.0));\n    float _3585 = _3573 - float(_3580);\n    vec3 param = d;\n    vec2 _3589 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3580;\n    vec2 param_4 = _3589;\n    vec3 _3599 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3585 < 0.00200000009499490261077880859375)\n    {\n        return _3599;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3580 + 1;\n    vec2 param_8 = _3589;\n    return mix(_3599, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3585));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3671 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3678 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3685 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3691 = dot(bx.xyz, d);\n    float _3695 = dot(by.xyz, d);\n    float _3699 = dot(bz.xyz, d);\n    float _3705;\n    if (_3691 > 9.9999999747524270787835121154785e-07)\n    {\n        _3705 = (1.0 - _3671) / _3691;\n    }\n    else\n    {\n        float _3719;\n        if (_3691 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3719 = ((-1.0) - _3671) / _3691;\n        }\n        else\n        {\n            _3719 = 1000000015047466219876688855040.0;\n        }\n        _3705 = _3719;\n    }\n    float tx = _3705;\n    float _3736;\n    if (_3695 > 9.9999999747524270787835121154785e-07)\n    {\n        _3736 = (1.0 - _3678) / _3695;\n    }\n    else\n    {\n        float _3749;\n        if (_3695 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3749 = ((-1.0) - _3678) / _3695;\n        }\n        else\n        {\n            _3749 = 1000000015047466219876688855040.0;\n        }\n        _3736 = _3749;\n    }\n    float ty = _3736;\n    float _3765;\n    if (_3699 > 9.9999999747524270787835121154785e-07)\n    {\n        _3765 = (1.0 - _3685) / _3699;\n    }\n    else\n    {\n        float _3778;\n        if (_3699 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3778 = ((-1.0) - _3685) / _3699;\n        }\n        else\n        {\n            _3778 = 1000000015047466219876688855040.0;\n        }\n        _3765 = _3778;\n    }\n    float _3790 = tx;\n    float _3793 = (_3790 > 0.0) ? _3790 : 1000000015047466219876688855040.0;\n    tx = _3793;\n    float _3794 = ty;\n    float _3797 = (_3794 > 0.0) ? _3794 : 1000000015047466219876688855040.0;\n    ty = _3797;\n    float _3807 = min(_3793, min(_3797, (_3765 > 0.0) ? _3765 : 1000000015047466219876688855040.0));\n    if (_3807 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3823 = (fa_world_pos + (d * _3807)) - posw.xyz;\n    vec3 _3828;\n    if (dot(_3823, _3823) > 1.0000000133514319600180897396058e-10)\n    {\n        _3828 = normalize(_3823);\n    }\n    else\n    {\n        _3828 = d;\n    }\n    return _3828;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3874 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3874 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3902 = rough * rough;\n            float _3933 = 0.60000002384185791015625 * _3902;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3902)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3933, 0.0500000007450580596923828125 + _3933, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3902 * 0.60000002384185791015625));\n        }\n        outc = base * _3874;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3992 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3992 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _4024 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_4024 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4671;\n        if (L.aniso >= 0.0)\n        {\n            _4671 = L.b;\n        }\n        else\n        {\n            _4671 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4671, v), _4671), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4707 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4707.x) + (vec3(L.f90) * _4707.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4765 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4765.x) + _4765.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4235 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4235.x) + vec3(_4235.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4794 = clamp(s.metallic, 0.0, 1.0);\n    float _4798 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4805 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4794));\n    vec3 f0 = _4805;\n    vec3 _4809 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4809;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4794;\n    float param_5 = _4798;\n    vec3 param_6 = _4805;\n    FaLayers _4826 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4826.on)\n    {\n        FaLayers param_7 = _4826;\n        vec3 param_8 = _4809;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4798;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4809;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4798;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5121;\n    if (fa_lm.z > 0.5)\n    {\n        _5121 = 0.0;\n    }\n    else\n    {\n        _5121 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5132 = _5121 < 1.0;\n    bool _5138;\n    if (_5132)\n    {\n        int param = li;\n        _5138 = fa_light_baked(param);\n    }\n    else\n    {\n        _5138 = _5132;\n    }\n    return _5138 ? _5121 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _676 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _689 = (c - (ru * hx)) - p;\n        vec3 _695 = ru * (2.0 * hx);\n        float _701 = max(dot(_695, _695), 9.9999999392252902907785028219223e-09);\n        float _705 = dot(_689, _695);\n        float t = clamp((-_705) / _701, 0.0, 1.0);\n        if (_676)\n        {\n            float _720 = dot(r, _695);\n            float _726 = _701 - (_720 * _720);\n            if (abs(_726) > (9.9999997473787516355514526367188e-06 * _701))\n            {\n                t = clamp(((dot(r, _689) * _720) - _705) / _726, 0.0, 1.0);\n            }\n        }\n        return (p + _689) + (_695 * t);\n    }\n    vec3 q = p;\n    float _758 = dot(r, axis);\n    bool _766;\n    if (_676)\n    {\n        _766 = abs(_758) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _766 = _676;\n    }\n    if (_766)\n    {\n        float _776 = dot(c - p, axis) / _758;\n        if (_776 > 0.0)\n        {\n            q = p + (r * _776);\n        }\n    }\n    vec3 _789 = q - c;\n    vec2 xy = vec2(dot(_789, ru), dot(_789, uu));\n    if (shape > 0.5)\n    {\n        float _804 = length(xy);\n        if (_804 > hx)\n        {\n            xy *= (hx / _804);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10)\n    {\n        _611 = atan(_600, _596) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _611 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_611 - floor(_611)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _446 = abs(d);\n    float _448 = _446.x;\n    float _450 = _446.y;\n    bool _451 = _448 >= _450;\n    bool _459;\n    if (_451)\n    {\n        _459 = _448 >= _446.z;\n    }\n    else\n    {\n        _459 = _451;\n    }\n    int _460;\n    if (_459)\n    {\n        _460 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _475;\n        if (_450 >= _446.z)\n        {\n            _475 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _475 = (d.z > 0.0) ? 4 : 5;\n        }\n        _460 = _475;\n    }\n    return _460;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _842 = fa_light_base(param);\n    bool _846 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _842;\n    vec4 _850 = fa_light_texel(param_1);\n    int param_2 = _842 + 1;\n    vec4 _855 = fa_light_texel(param_2);\n    float _858 = _855.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _870 = _846 && (_858 > 2.5);\n    fa_light_is_area = _870;\n    bool _872 = _858 < 0.5;\n    vec3 l;\n    if (_872)\n    {\n        l = normalize(_850.xyz);\n        if (_846)\n        {\n            int param_3 = _842 + 6;\n            vec4 _886 = fa_light_texel(param_3);\n            if (_886.z > 0.5)\n            {\n                int param_4 = _842 + 4;\n                vec4 _896 = fa_light_texel(param_4);\n                int param_5 = _842 + 5;\n                vec4 _901 = fa_light_texel(param_5);\n                vec2 param_6 = _886.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _896.xyz) * _896.w, (-dot(world_pos, _901.xyz)) * _901.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _931 = _850.xyz;\n        vec3 _933 = _931 - world_pos;\n        vec3 to_light = _933;\n        float _936 = length(_933);\n        float reach = _936;\n        bool front = true;\n        if (_870)\n        {\n            int param_8 = _842 + 7;\n            reach = max(_936 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _842 + 4;\n            vec4 _960 = fa_light_texel(param_9);\n            int param_10 = _842 + 5;\n            vec4 _965 = fa_light_texel(param_10);\n            int param_11 = _842 + 6;\n            vec4 _970 = fa_light_texel(param_11);\n            float _971 = _970.w;\n            int param_12 = _842 + 2;\n            vec3 _978 = normalize(fa_light_texel(param_12).xyz);\n            bool _980 = _971 > 1.5;\n            bool _988;\n            if (!_980)\n            {\n                _988 = dot(_978, to_light) < 0.0;\n            }\n            else\n            {\n                _988 = _980;\n            }\n            front = _988;\n            vec3 r = vec3(0.0);\n            vec3 _997 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1001 = dot(n, n) > 0.5;\n            bool _1009;\n            if (_1001)\n            {\n                _1009 = dot(_997, _997) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1009 = _1001;\n            }\n            if (_1009)\n            {\n                r = reflect(-normalize(_997), normalize(n));\n            }\n            vec3 param_13 = _931;\n            vec3 param_14 = _978;\n            vec3 param_15 = _960.xyz;\n            vec3 param_16 = _965.xyz;\n            float param_17 = _960.w;\n            float param_18 = _965.w;\n            float param_19 = _971;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1045 = length(to_light);\n        dist = _1045;\n        l = to_light / vec3(max(_1045, 9.9999997473787516355514526367188e-05));\n        float _1059 = reach / max(_850.w, 0.001000000047497451305389404296875);\n        float _1065 = clamp(1.0 - (_1059 * _1059), 0.0, 1.0);\n        float _1067;\n        if (front)\n        {\n            _1067 = _1065 * _1065;\n        }\n        else\n        {\n            _1067 = 0.0;\n        }\n        atten = _1067;\n        bool _1078 = _858 < 2.5;\n        if ((_858 > 1.5) && _1078)\n        {\n            int param_22 = _842 + 2;\n            vec4 _1086 = fa_light_texel(param_22);\n            float _1096 = _1086.w;\n            int param_23 = _842 + 3;\n            vec4 _1101 = fa_light_texel(param_23);\n            float _1102 = _1101.x;\n            float cos_inner = _1102;\n            if (_1102 > 1.5)\n            {\n                cos_inner = mix(_1096, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1096, cos_inner, dot(-l, normalize(_1086.xyz)));\n        }\n        if (_846 && (_858 < 1.5))\n        {\n            int param_24 = _842 + 6;\n            vec4 _1126 = fa_light_texel(param_24);\n            if (_1126.z > 0.5)\n            {\n                vec3 _1134 = -to_light;\n                int param_25 = _842 + 4;\n                int param_26 = _842 + 5;\n                vec3 _1148 = fa_light_texel(param_25).xyz;\n                vec3 _1152 = fa_light_texel(param_26).xyz;\n                vec3 _1161 = vec3(dot(_1134, _1148), dot(_1134, _1152), dot(_1134, cross(_1148, _1152)));\n                vec3 param_27 = _1161;\n                int _1165 = fa_cube_face(param_27);\n                int param_28 = _1165;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1192 = vec2(dot(_1161, cross(param_29, param_30)), dot(_1161, param_30)) / vec2(max(dot(_1161, param_29), 9.9999997473787516355514526367188e-05));\n                int _1196 = _1165 / 3;\n                vec2 param_31 = _1126.xy + (vec2(float(_1165 - (_1196 * 3)), float(_1196)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1192.x), 0.5 - (0.5 * _1192.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _842 + 7;\n            vec4 _1226 = fa_light_texel(param_33);\n            if (_1226.z > 0.5)\n            {\n                int param_34 = _842 + 2;\n                int param_35 = _842 + 4;\n                int param_36 = _842 + 5;\n                vec2 param_37 = _1226.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_846 && _1078)\n            {\n                int param_42 = _842 + 6;\n                vec4 _1273 = fa_light_texel(param_42);\n                int param_43 = _842 + 7;\n                vec4 _1278 = fa_light_texel(param_43);\n                bool _1281 = _1273.z > 0.5;\n                bool _1288;\n                if (!_1281)\n                {\n                    _1288 = _1278.z > 0.5;\n                }\n                else\n                {\n                    _1288 = _1281;\n                }\n                if (_1288)\n                {\n                    int param_44 = _842 + 2;\n                    vec4 _1295 = fa_light_texel(param_44);\n                    vec3 _1299 = normalize(_1295.xyz);\n                    int param_45 = _842 + 4;\n                    vec4 _1304 = fa_light_texel(param_45);\n                    int param_46 = _842 + 5;\n                    vec4 _1309 = fa_light_texel(param_46);\n                    if (_1281)\n                    {\n                        vec3 _1317 = -to_light;\n                        float _1324 = _1295.w;\n                        float _1340 = 0.5 / max(dot(_1317, _1299) * (sqrt(max(1.0 - (_1324 * _1324), 0.0)) / max(_1324, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1273.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1317, _1304.xyz) * _1340), 0.5 - (dot(_1317, _1309.xyz) * _1340));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1278.z > 0.5)\n                    {\n                        vec2 param_49 = _1278.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1299;\n                        vec3 param_52 = _1304.xyz;\n                        vec3 param_53 = _1309.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6948 = _855.xyz * atten;\n    if (_846)\n    {\n        _6948 *= fa_light_tint;\n    }\n    int _1408;\n    if (_872)\n    {\n        _1408 = 0;\n    }\n    else\n    {\n        _1408 = ((_858 > 1.5) && (_858 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6948, atten, 1.0, dist, _1408);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2197 = fa_shadow_depth(param, param_1);\n    float _2201;\n    if (conv.x < 0.5)\n    {\n        _2201 = _2197;\n    }\n    else\n    {\n        _2201 = (conv.y * conv.z) / (conv.z - (_2197 * (conv.z - conv.y)));\n    }\n    return _2201;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2247 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2253 = vec2(cos(_2247), sin(_2247));\n    vec2 dir = _2253;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2262;\n        if (k < 0.0)\n        {\n            _2262 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2262 = k;\n        }\n        float _2281 = clamp((_2262 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2300 = sqrt((float(i) + 0.5) * 0.0625) * _2281;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2300));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2314 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2314 < (zr - (_2300 * plane)))\n            {\n                sum += _2314;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2342 = sum / cnt;\n        float _2352;\n        if (k < 0.0)\n        {\n            _2352 = (-k) / max(_2342, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2352 = k;\n        }\n        radius = clamp(((max(zr - _2342, 0.0) * unit) * _2352) / texel_m, 1.5, 16.0);\n        dir = _2253;\n    }\n    float lit = 0.0;\n    int _2378 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2378; i_1++)\n    {\n        float _2397 = sqrt((float(i_1) + 0.5) / float(_2378)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2397));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2397 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2378);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2602 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2609;\n    if (!_2602)\n    {\n        _2609 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2609 = _2602;\n    }\n    if (_2609)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2622 = fa_light_texel(param);\n    float _2623 = _2622.x;\n    if (_2623 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2632 = int(_2623 + 0.5);\n    int param_1 = _2632;\n    vec4 _2636 = fa_light_texel(param_1);\n    int param_2 = _2632 + 1;\n    vec4 _2641 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2644 = _2636.y;\n    if (_2644 > 0.0)\n    {\n        float _2661 = 1.0 - smoothstep(0.75 * _2644, _2644, length(world - fa_shadows[27].xyz));\n        fade = _2661;\n        if (_2661 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2636.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2685 = (_2632 + 2) + (face * 6);\n    int param_4 = _2685;\n    int param_5 = _2685 + 1;\n    int param_6 = _2685 + 3;\n    vec4 _2699 = fa_light_texel(param_6);\n    int param_7 = _2685 + 4;\n    vec4 _2704 = fa_light_texel(param_7);\n    int param_8 = _2685 + 5;\n    vec4 _2709 = fa_light_texel(param_8);\n    float _2721 = _2709.x * max(dot(_2699, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2726 = clamp(dot(n, l), 0.0, 1.0);\n    float _2749 = clamp(dot(n, _2699.xyz), -1.0, 1.0);\n    float _2768 = min(sqrt(1.0 - (_2749 * _2749)) / max(abs(dot(n, world - lpos)) / max(dot(_2699, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2771 = _2641.y;\n    float _2773;\n    if (_2771 > 0.0)\n    {\n        _2773 = _2771;\n    }\n    else\n    {\n        _2773 = 1.5 * _2721;\n    }\n    vec4 _2793 = vec4(world + (n * (_2773 * sqrt(1.0 - (_2726 * _2726)))), 1.0);\n    float _2797 = dot(_2699, _2793);\n    float _2800 = _2709.y;\n    if (_2797 < _2800)\n    {\n        return 1.0;\n    }\n    vec2 _2815 = vec2(dot(fa_light_texel(param_4), _2793), dot(fa_light_texel(param_5), _2793)) / vec2(_2797);\n    float _2817 = _2815.x;\n    bool _2820 = _2817 < _2704.x;\n    bool _2829;\n    if (!_2820)\n    {\n        _2829 = _2817 > _2704.z;\n    }\n    else\n    {\n        _2829 = _2820;\n    }\n    bool _2838;\n    if (!_2829)\n    {\n        _2838 = _2815.y < _2704.y;\n    }\n    else\n    {\n        _2838 = _2829;\n    }\n    bool _2847;\n    if (!_2838)\n    {\n        _2847 = _2815.y > _2704.w;\n    }\n    else\n    {\n        _2847 = _2838;\n    }\n    if (_2847)\n    {\n        return 1.0;\n    }\n    float _2853 = _2641.x;\n    float _2855;\n    if (_2853 > 0.0)\n    {\n        _2855 = _2853;\n    }\n    else\n    {\n        _2855 = 1.5 * _2721;\n    }\n    vec2 param_9 = _2815;\n    vec4 param_10 = _2704;\n    float param_11 = _2797 - (_2855 * (1.0 + (0.5 * _2768)));\n    float param_12 = _2721;\n    float param_13 = 1.0;\n    float param_14 = _2709.z * 0.25;\n    float param_15 = (_2721 * min(_2768, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2800, _2709.z);\n    int param_17 = int(_2636.z + 0.5);\n    float param_18 = _2636.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2140;\n    if (i == 0)\n    {\n        _2140 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2156;\n        if (i == 1)\n        {\n            _2156 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2164;\n            if (i == 2)\n            {\n                _2164 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2164 = fa_shadows[24].w;\n            }\n            _2156 = _2164;\n        }\n        _2140 = _2156;\n    }\n    return _2140;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2443 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2448 = clamp(dot(n, l), 0.0, 1.0);\n    float _2454 = sqrt(1.0 - (_2448 * _2448));\n    float _2462 = min(_2454 / max(_2448, 0.20000000298023223876953125), 4.0);\n    float _2467;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2467 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2467 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2492 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2467 * _2454)), 1.0);\n    float _2499 = _2492.x;\n    bool _2502 = _2499 < fa_shadows[ci * 1 + 16].x;\n    bool _2511;\n    if (!_2502)\n    {\n        _2511 = _2499 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2511 = _2502;\n    }\n    bool _2520;\n    if (!_2511)\n    {\n        _2520 = _2492.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2520 = _2511;\n    }\n    bool _2529;\n    if (!_2520)\n    {\n        _2529 = _2492.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2529 = _2520;\n    }\n    bool _2536;\n    if (!_2529)\n    {\n        _2536 = _2492.z > 1.0;\n    }\n    else\n    {\n        _2536 = _2529;\n    }\n    if (_2536)\n    {\n        return -1.0;\n    }\n    float _2544;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2544 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2544 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2492.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2492.z - ((_2544 * (1.0 + (0.5 * _2462))) / _2443);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2443;\n    float param_5 = _2443 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2462, 3.0)) * 0.5) / _2443;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2922 = int(fa_shadows[25].x + 0.5);\n    if (_2922 < 1)\n    {\n        return 1.0;\n    }\n    float _2937 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2922 - 1;\n    if (_2937 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2949 = _2922 > 1;\n    bool _2956;\n    if (_2949)\n    {\n        _2956 = _2937 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2956 = _2949;\n    }\n    if (_2956)\n    {\n        ci = 1;\n    }\n    bool _2960 = _2922 > 2;\n    bool _2967;\n    if (_2960)\n    {\n        _2967 = _2937 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2967 = _2960;\n    }\n    if (_2967)\n    {\n        ci = 2;\n    }\n    bool _2971 = _2922 > 3;\n    bool _2978;\n    if (_2971)\n    {\n        _2978 = _2937 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2978 = _2971;\n    }\n    if (_2978)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _2989 = min(_2922, 4);\n    float _3030;\n    for (int c = ci; c < _2989; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3009 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3009;\n            break;\n        }\n        if (_3009 < 0.0)\n        {\n            continue;\n        }\n        s = _3009;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3030 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3030 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3049 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3030, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2937 - (fa_shadow_split_at(param_7) - _3049)) / _3049, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3081;\n        if ((ci + 1) < _2922)\n        {\n            _3081 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3081 = 1.0;\n        }\n        s = mix(s, _3081, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    bool _3186 = fa_mesh_fs_params[25].y > 0.5;\n    bool _3192;\n    if (_3186)\n    {\n        _3192 = fa_mesh_fs_params[5].z > 0.5;\n    }\n    else\n    {\n        _3192 = _3186;\n    }\n    if (_3192)\n    {\n        vec4 _3202 = vec4(fa_world_pos, 1.0);\n        float _3208 = dot(fa_mesh_fs_params[28], _3202);\n        if (_3208 > 9.9999997473787516355514526367188e-05)\n        {\n            vec2 _3227 = vec2(dot(fa_mesh_fs_params[26], _3202), dot(fa_mesh_fs_params[27], _3202)) / vec2(_3208);\n            float _3232 = (_3227.x * 0.5) + 0.5;\n            float _3236;\n            if (fa_mesh_fs_params[24].y > 0.5)\n            {\n                _3236 = (_3227.y * 0.5) + 0.5;\n            }\n            else\n            {\n                _3236 = 0.5 - (_3227.y * 0.5);\n            }\n            bool _3252 = _3232 >= 0.0;\n            bool _3258;\n            if (_3252)\n            {\n                _3258 = _3232 < 1.0;\n            }\n            else\n            {\n                _3258 = _3252;\n            }\n            bool _3264;\n            if (_3258)\n            {\n                _3264 = _3236 >= 0.0;\n            }\n            else\n            {\n                _3264 = _3258;\n            }\n            bool _3270;\n            if (_3264)\n            {\n                _3270 = _3236 < 1.0;\n            }\n            else\n            {\n                _3270 = _3264;\n            }\n            if (_3270)\n            {\n                vec4 _3296 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_3232, _3236) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n                float _3306 = dot(fa_mesh_fs_params[29].xyz, fa_world_pos) + fa_mesh_fs_params[29].w;\n                bool _3309 = _3296.w > 0.5;\n                bool _3323;\n                if (_3309)\n                {\n                    _3323 = abs(_3306 - _3296.x) <= ((0.00200000009499490261077880859375 * _3306) + 0.00999999977648258209228515625);\n                }\n                else\n                {\n                    _3323 = _3309;\n                }\n                if (_3323)\n                {\n                    return _3296.y;\n                }\n            }\n        }\n    }\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4865 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4872;\n    if (!_4865)\n    {\n        _4872 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4872 = _4865;\n    }\n    if (_4872)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4885 = fa_light_texel(param);\n    float _4886 = _4885.y;\n    float len = _4886;\n    if (_4886 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4898 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4907 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4898);\n    if (_4907 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4913 = len;\n    float _4916 = min(_4913, 0.89999997615814208984375 * dist);\n    len = _4916;\n    float _4921 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4898);\n    float _4926 = _4921 + (0.5 * _4916);\n    vec3 _4932 = world + (gn * _4921);\n    float _4934 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4995;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4949 = (float(k) + _4934) * 0.083333335816860198974609375;\n        vec3 _4957 = _4932 + (l * (_4949 * len));\n        vec4 _4963 = vec4(_4957, 1.0);\n        float _4968 = dot(fa_mesh_fs_params[28], _4963);\n        if (_4968 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4986 = vec2(dot(fa_mesh_fs_params[26], _4963), dot(fa_mesh_fs_params[27], _4963)) / vec2(_4968);\n        float _4990 = _4986.x * 0.5;\n        float _4991 = _4990 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4995 = (_4986.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4995 = 0.5 - (_4986.y * 0.5);\n        }\n        bool _5011 = _4991 < 0.0;\n        bool _5018;\n        if (!_5011)\n        {\n            _5018 = _4991 >= 1.0;\n        }\n        else\n        {\n            _5018 = _5011;\n        }\n        bool _5025;\n        if (!_5018)\n        {\n            _5025 = _4995 < 0.0;\n        }\n        else\n        {\n            _5025 = _5018;\n        }\n        bool _5032;\n        if (!_5025)\n        {\n            _5032 = _4995 >= 1.0;\n        }\n        else\n        {\n            _5032 = _5025;\n        }\n        if (_5032)\n        {\n            break;\n        }\n        vec4 _5056 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4991, _4995) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_5056.w < 0.5)\n        {\n            continue;\n        }\n        float _5074 = (dot(fa_mesh_fs_params[29].xyz, _4957) + fa_mesh_fs_params[29].w) - _5056.x;\n        if ((_5074 > _4921) && (_5074 < _4926))\n        {\n            occ = max(occ, (1.0 - (_4949 * _4949)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4991, 0.5 - _4990), min(_4995, 1.0 - _4995))));\n        }\n    }\n    return 1.0 - (occ * _4907);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5177 = fa_baked_keep(param);\n    if (_5177 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5203 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7081 = _5203.color;\n    float _7082 = _5203.attenuation;\n    float _7083 = _5203.shadow;\n    bool _5206 = _5203.type == 0;\n    if (_5206 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5203.direction;\n        float _5217 = fa_shadow_factor(param_5, param_6);\n        _7083 = _5217;\n        _7081 *= _5217;\n    }\n    else\n    {\n        bool _5228 = _5203.type != 0;\n        bool _5234;\n        if (_5228)\n        {\n            _5234 = _7082 > 0.0;\n        }\n        else\n        {\n            _5234 = _5228;\n        }\n        if (_5234)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5203.direction;\n            float _5253 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7083 = _5253;\n            _7081 *= _5253;\n        }\n    }\n    bool _5263 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5269;\n    if (_5263)\n    {\n        _5269 = _7082 > 0.0;\n    }\n    else\n    {\n        _5269 = _5263;\n    }\n    if (_5269)\n    {\n        float _5276;\n        if (_5206)\n        {\n            _5276 = 1000000000.0;\n        }\n        else\n        {\n            _5276 = _5203._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5203.direction;\n        float param_18 = _5276;\n        float _5294 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7083 *= _5294;\n        _7081 *= _5294;\n    }\n    float _5307 = _7082;\n    float _5308 = _5307 * _5177;\n    _7082 = _5308;\n    vec3 _5312 = _7081;\n    vec3 _5313 = _5312 * _5177;\n    _7081 = _5313;\n    return LightSample(_5203.direction, _5313, _5308, _7083, _5203._distance, _5203.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3109 = int(fa_shadows[25].x + 0.5);\n    float _3119 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3124 = _3109 > 0;\n    bool _3133;\n    if (_3124)\n    {\n        int param = _3109 - 1;\n        _3133 = _3119 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3133 = _3124;\n    }\n    if (_3133)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3139 = _3109 > 1;\n        bool _3146;\n        if (_3139)\n        {\n            _3146 = _3119 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3146 = _3139;\n        }\n        if (_3146)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3152 = _3109 > 2;\n        bool _3159;\n        if (_3152)\n        {\n            _3159 = _3119 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3159 = _3152;\n        }\n        if (_3159)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3165 = _3109 > 3;\n        bool _3172;\n        if (_3165)\n        {\n            _3172 = _3119 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3172 = _3165;\n        }\n        if (_3172)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6766 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6766 = -_6766;\n    }\n    vec3 _6389 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6766, fa_world_tangent, fa_uv, fa_vertex_color, _6389, gl_FrontFacing);\n    Surface _6397 = fa_standard_surface(param_1);\n    vec3 _6805 = _6397.albedo;\n    float _6806 = _6397.alpha;\n    vec3 _6807 = _6397.normal;\n    float _6808 = _6397.metallic;\n    float _6809 = _6397.roughness;\n    float _6810 = _6397.occlusion;\n    vec3 _6811 = _6397.emission;\n    float _6812 = _6397.clearcoat;\n    float _6813 = _6397.clearcoat_roughness;\n    vec3 _6814 = _6397.sheen_color;\n    float _6815 = _6397.sheen_roughness;\n    float _6816 = _6397.anisotropy;\n    float _6817 = _6397.anisotropy_rotation;\n    float _6818 = _6397.specular;\n    float _6819 = _6397.ior;\n    vec3 _6820 = _6397.specular_color;\n    float _6821 = _6397.transmission;\n    float _6822 = _6397.thickness;\n    vec3 _6823 = _6397.attenuation_color;\n    float _6824 = _6397.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6766, fa_world_tangent, fa_uv, fa_vertex_color, _6389, gl_FrontFacing);\n    Surface param_3 = _6397;\n    surface(param_2, param_3);\n    _6805 = param_3.albedo;\n    _6806 = param_3.alpha;\n    _6807 = param_3.normal;\n    _6808 = param_3.metallic;\n    _6809 = param_3.roughness;\n    _6810 = param_3.occlusion;\n    _6811 = param_3.emission;\n    _6812 = param_3.clearcoat;\n    _6813 = param_3.clearcoat_roughness;\n    _6814 = param_3.sheen_color;\n    _6815 = param_3.sheen_roughness;\n    _6816 = param_3.anisotropy;\n    _6817 = param_3.anisotropy_rotation;\n    _6818 = param_3.specular;\n    _6819 = param_3.ior;\n    _6820 = param_3.specular_color;\n    _6821 = param_3.transmission;\n    _6822 = param_3.thickness;\n    _6823 = param_3.attenuation_color;\n    _6824 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6766;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6805 = param_6;\n    _6807 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6805;\n    }\n    else\n    {\n        vec3 _6436 = _6807;\n        vec3 _6437 = normalize(_6436);\n        _6807 = _6437;\n        vec3 param_8 = _6437;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _6766, fa_world_tangent, fa_uv, fa_vertex_color, _6389, gl_FrontFacing);\n        Surface param_10 = Surface(_6805, _6806, _6807, _6808, _6809, _6810, _6811, _6812, _6813, _6814, _6815, _6816, _6817, _6818, _6819, _6820, _6821, _6822, _6823, _6824);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6456 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6456; ln++)\n        {\n            int param_12 = ln;\n            int _6469 = fa_cl_light(param_12);\n            int param_13 = _6469;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6469;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _6766;\n            LightSample _6485 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _6766, fa_world_tangent, fa_uv, fa_vertex_color, _6389, gl_FrontFacing);\n            Surface param_18 = Surface(_6805, _6806, _6807, _6808, _6809, _6810, _6811, _6812, _6813, _6814, _6815, _6816, _6817, _6818, _6819, _6820, _6821, _6822, _6823, _6824);\n            LightSample param_19 = _6485;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6500 = result;\n    vec3 _6501 = _6500 + _6811;\n    result = _6501;\n    vec3 param_20 = _6501;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6510 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6517;\n    if (!_6510)\n    {\n        _6517 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6517 = _6510;\n    }\n    if (_6517)\n    {\n        vec3 _6526 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6532 = dot(_6526, fa_mesh_fs_params[9].xyz);\n        bool _6536 = fa_mesh_fs_params[9].w > 0.5;\n        float _6537;\n        if (_6536)\n        {\n            _6537 = _6532;\n        }\n        else\n        {\n            _6537 = length(_6526);\n        }\n        float _6549 = _6537 - fa_mesh_fs_params[8].x;\n        if (_6549 > 0.0)\n        {\n            float _6558 = fa_mesh_fs_params[7].w * _6549;\n            float tau = _6558 * _6558;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6574;\n                if (_6536)\n                {\n                    _6574 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6532);\n                }\n                else\n                {\n                    _6574 = fa_mesh_fs_params[0].y;\n                }\n                float _6595 = mix(_6574, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6537, 0.0, 1.0));\n                float _6599 = fa_world_pos.y - _6595;\n                float _6604 = _6595 - fa_mesh_fs_params[8].z;\n                float _6609 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6612 = _6604 <= 0.0;\n                bool _6613 = !_6612;\n                bool _6619;\n                if (_6613)\n                {\n                    _6619 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6619 = _6612;\n                }\n                float _6620;\n                if (_6619)\n                {\n                    _6620 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6620 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6604, 80.0));\n                }\n                bool _6647;\n                if (_6613)\n                {\n                    _6647 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6647 = _6612;\n                }\n                float _6648;\n                if (_6647)\n                {\n                    _6648 = fa_mesh_fs_params[8].y * _6604;\n                }\n                else\n                {\n                    _6648 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6604, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6673 = _6609 <= 0.0;\n                bool _6680;\n                if (!_6673)\n                {\n                    _6680 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6680 = _6673;\n                }\n                float _6681;\n                if (_6680)\n                {\n                    _6681 = fa_mesh_fs_params[8].y * _6609;\n                }\n                else\n                {\n                    _6681 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6609, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6708;\n                if (abs(_6599) < 0.001000000047497451305389404296875)\n                {\n                    _6708 = _6620;\n                }\n                else\n                {\n                    _6708 = (_6681 - _6648) / _6599;\n                }\n                tau += (_6549 * max(_6708, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6806);\n}\n\n",
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
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_136",
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
            "inst_name": "_183",
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
            "inst_name": "_498",
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
            "inst_name": "_2150",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 30,
                "offset": 0,
                "glsl_name": "fa_shadows"
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_vel_params[9];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 9) in vec4 fa_prev_r0;\nlayout(location = 10) in vec4 fa_prev_r1;\nlayout(location = 11) in vec4 fa_prev_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _97 = cross(model[1].xyz, model[2].xyz);\n    float _101 = (dot(model[0].xyz, _97) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_97 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _101, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _101), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    return fa_rows_to_mat4(param, param_1, param_2);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _231;\n    if (has_prev)\n    {\n        _231 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _231 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _246 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _455 = _246.world_pos;\n    mat4 _250 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _257 = vec4(_455, 1.0);\n    fa_world_pos = _455;\n    fa_world_normal = _246.world_normal;\n    fa_world_tangent = _246.world_tangent;\n    fa_uv = _246.uv;\n    fa_vertex_color = _246.color;\n    fa_pre_depth = -(_250 * _257).z;\n    fa_pre_r0 = vec3(_250[0].x, _250[1].x, _250[2].x);\n    fa_pre_r1 = vec3(_250[0].y, _250[1].y, _250[2].y);\n    fa_pre_r2 = vec3(_250[0].z, _250[1].z, _250[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _257;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_231)\n    {\n        vec4 _330 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _257).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_455 + (fa_prev_model() * _330).xyz) - (model * _330).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    bool param_6 = true;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5, param_6);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "glsl_name": "fa_prev_r0"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_prev_r1"
          },
          {
            "slot": 11,
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
            "inst_name": "_57",
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
            "inst_name": "_225",
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
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nuniform vec4 fa_vel_params[9];\nlayout(binding = 0) uniform sampler2D fa_prev_pal_tex_fa_prev_pal_smp;\n\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) out vec3 fa_vel_cur;\nlayout(location = 10) out vec3 fa_vel_prev;\nlayout(location = 11) in vec4 fa_prev_r0;\nlayout(location = 12) in vec4 fa_prev_r1;\nlayout(location = 13) in vec4 fa_prev_r2;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 fa_vtime;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _204 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_204 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_204 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_204 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_time_now()\n{\n    return fa_mesh_vs_params[9];\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _113 = cross(model[1].xyz, model[2].xyz);\n    float _117 = (dot(model[0].xyz, _113) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_113 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _117, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _117), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nmat4 fa_rows_to_mat4(vec4 r0, vec4 r1, vec4 r2)\n{\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvec4 fa_prev_pal_texel(int t)\n{\n    return texelFetch(fa_prev_pal_tex_fa_prev_pal_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nmat4 fa_prev_skin_matrix(vec4 joints, vec4 weights, int base)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _332 = base + (int((joints[i] * 255.0) + 0.5) * 3);\n        int param = _332;\n        r0 += (fa_prev_pal_texel(param) * weights[i]);\n        int param_1 = _332 + 1;\n        r1 += (fa_prev_pal_texel(param_1) * weights[i]);\n        int param_2 = _332 + 2;\n        r2 += (fa_prev_pal_texel(param_2) * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nmat4 fa_prev_model()\n{\n    vec4 param = fa_prev_r0;\n    vec4 param_1 = fa_prev_r1;\n    vec4 param_2 = fa_prev_r2;\n    vec4 param_3 = fa_joints;\n    vec4 param_4 = fa_weights;\n    int param_5 = int(fa_vel_params[8].w + 0.5);\n    return fa_rows_to_mat4(param, param_1, param_2) * fa_prev_skin_matrix(param_3, param_4, param_5);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color, bool has_prev)\n{\n    bool _475;\n    if (has_prev)\n    {\n        _475 = fa_vel_params[8].x > 0.5;\n    }\n    else\n    {\n        _475 = has_prev;\n    }\n    fa_vtime = fa_time_now();\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _490 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _720 = _490.world_pos;\n    mat4 _494 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _501 = vec4(_720, 1.0);\n    fa_world_pos = _720;\n    fa_world_normal = _490.world_normal;\n    fa_world_tangent = _490.world_tangent;\n    fa_uv = _490.uv;\n    fa_vertex_color = _490.color;\n    fa_pre_depth = -(_494 * _501).z;\n    fa_pre_r0 = vec3(_494[0].x, _494[1].x, _494[2].x);\n    fa_pre_r1 = vec3(_494[0].y, _494[1].y, _494[2].y);\n    fa_pre_r2 = vec3(_494[0].z, _494[1].z, _494[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _501;\n    fa_vel_cur = vec3(0.0, 0.0, 1.0);\n    fa_vel_prev = vec3(0.0);\n    if (_475)\n    {\n        vec4 _574 = vec4(position, 1.0);\n        fa_vel_cur = vec3((mat4(fa_vel_params[0], fa_vel_params[1], fa_vel_params[2], fa_vel_params[3]) * _501).xyw);\n        fa_vel_prev = vec3((mat4(fa_vel_params[4], fa_vel_params[5], fa_vel_params[6], fa_vel_params[7]) * vec4((_720 + (fa_prev_model() * _574).xyz) - (model * _574).xyz, 1.0)).xyw);\n    }\n}\n\nvoid main()\n{\n    fa_vtime = vec4(0.0);\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    bool param_8 = fa_vel_params[8].z > 0.5;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7, param_8);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\nlayout(location = 9) in vec3 fa_vel_cur;\nlayout(location = 10) in vec3 fa_vel_prev;\nlayout(location = 1) out vec2 fa_frag_velocity;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _230 = fa_tex_fix(param_2, param_3);\n    vec4 _889 = base_t;\n    _889.x = _230.x;\n    _889.y = _230.y;\n    _889.z = _230.z;\n    base_t = _889;\n    vec4 _246 = (_889 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _844 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _282 = fa_tex_fix(param_6, param_7);\n        vec3 _286 = (_282 * 2.0) - vec3(1.0);\n        vec2 _291 = _286.xy * fa_mesh_fs_params[6].x;\n        vec3 _897 = _286;\n        _897.x = _291.x;\n        _897.y = _291.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _897;\n        _844 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _322 = fa_tex_fix(param_12, param_13);\n    vec4 _900 = mrt;\n    _900.x = _322.x;\n    _900.y = _322.y;\n    _900.z = _322.z;\n    mrt = _900;\n    vec4 _354 = texture(fa_occlusion_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _354.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _366 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv, fa_mesh_fs_params[12].w).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _849 = fa_mesh_fs_params[20].x;\n    float _850 = fa_mesh_fs_params[20].y;\n    float _853 = fa_mesh_fs_params[20].z;\n    float _852 = fa_mesh_fs_params[21].w;\n    float _855 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _849 *= _366.y;\n            _850 *= _366.z;\n            _852 *= _354.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _853 *= mrt.x;\n            _855 *= mrt.w;\n        }\n    }\n    return Surface(_246.xyz, _246.w, _844, clamp(fa_mesh_fs_params[5].x * _322.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _322.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_366.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _849, _850, fa_mesh_fs_params[21].xyz, _852, _853, fa_mesh_fs_params[20].w, _855, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _739 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _739 = -_739;\n    }\n    vec3 _550 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _739, fa_world_tangent, fa_uv, fa_vertex_color, _550, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _565 = normalize(param_2.normal);\n    vec3 _580 = normalize(vec3(dot(fa_pre_r0, _565), dot(fa_pre_r1, _565), dot(fa_pre_r2, _565)));\n    float _592 = _580.z;\n    vec2 e = _580.xy / vec2((abs(_580.x) + abs(_580.y)) + abs(_592));\n    if (_592 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n    vec2 motion = vec2(1024.0);\n    bool _636 = fa_vel_cur.z > 9.9999997473787516355514526367188e-06;\n    bool _643;\n    if (_636)\n    {\n        _643 = fa_vel_prev.z > 9.9999997473787516355514526367188e-06;\n    }\n    else\n    {\n        _643 = _636;\n    }\n    if (_643)\n    {\n        motion = clamp(((vec2(fa_vel_prev.x, -fa_vel_prev.y) / vec2(fa_vel_prev.z)) * 0.5) - ((vec2(fa_vel_cur.x, -fa_vel_cur.y) / vec2(fa_vel_cur.z)) * 0.5), vec2(-4.0), vec2(4.0));\n    }\n    fa_frag_velocity = motion;\n}\n\n",
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
            "inst_name": "_74",
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
            "inst_name": "_213",
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
            "inst_name": "_470",
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
            "slot": 1,
            "stage": "fragment",
            "size": 848,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_214",
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
    }
  }
}
