{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "ae26515a48b1a8d2e7a58b8583b7398bc5ad5b1e5314aaacf65f28e91c149fe7",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4188[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1426 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1433;\n    if (!_1426)\n    {\n        _1433 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1433 = _1426;\n    }\n    bool _1441;\n    if (!_1433)\n    {\n        _1441 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1441 = _1433;\n    }\n    bool _1448;\n    if (!_1441)\n    {\n        _1448 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1448 = _1441;\n    }\n    bool _1455;\n    if (!_1448)\n    {\n        _1455 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1455 = _1448;\n    }\n    if (_1455)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1465 = vec4(world_pos, 1.0);\n    float _1471 = dot(fa_mesh_fs_params[16], _1465);\n    if (!(_1471 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1493 = vec2(dot(fa_mesh_fs_params[14], _1465), dot(fa_mesh_fs_params[15], _1465)) / vec2(_1471);\n    int _1497 = int(fa_mesh_fs_params[18].x);\n    int _1501 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1501) + clamp(int(floor(((_1493.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1501 - 1)) * _1497)) + clamp(int(floor(((_1493.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1497 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1577 = fa_cluster_texel(param);\n    return ivec2(int(_1577.x), int(_1577.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5011 = fa_cluster_lookup(param);\n    fa_cl_slot = _5011.x;\n    fa_cl_local = _5011.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5223 = fa_linear_to_srgb(param);\n        c = _5223;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5231 = fa_srgb_to_linear(param_1);\n            c = _5231;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _380;\n    if (i.front_facing)\n    {\n        _380 = i.world_normal;\n    }\n    else\n    {\n        _380 = -i.world_normal;\n    }\n    vec3 _404 = normalize(i.world_tangent.xyz - (_380 * dot(_380, i.world_tangent.xyz)));\n    vec3 _431 = normalize(((_404 * m.x) + ((cross(_380, _404) * i.world_tangent.w) * m.y)) + (_380 * m.z));\n    vec3 _434;\n    if (i.front_facing)\n    {\n        _434 = _431;\n    }\n    else\n    {\n        _434 = -_431;\n    }\n    return _434;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5262 = fa_tex_fix(param_2, param_3);\n    vec4 _7146 = base_t;\n    _7146.x = _5262.x;\n    _7146.y = _5262.y;\n    _7146.z = _5262.z;\n    base_t = _7146;\n    vec4 _5276 = (_7146 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6952 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5308 = fa_tex_fix(param_6, param_7);\n        vec3 _5311 = (_5308 * 2.0) - vec3(1.0);\n        vec2 _5316 = _5311.xy * fa_mesh_fs_params[6].x;\n        vec3 _7154 = _5311;\n        _7154.x = _5316.x;\n        _7154.y = _5316.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7154;\n        _6952 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5344 = fa_tex_fix(param_12, param_13);\n    vec4 _7157 = mrt;\n    _7157.x = _5344.x;\n    _7157.y = _5344.y;\n    _7157.z = _5344.z;\n    mrt = _7157;\n    vec4 _5372 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5372.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5383 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5413 = fa_tex_fix(param_20, param_21);\n    float _6957 = fa_mesh_fs_params[20].x;\n    float _6958 = fa_mesh_fs_params[20].y;\n    float _6961 = fa_mesh_fs_params[20].z;\n    float _6960 = fa_mesh_fs_params[21].w;\n    float _6963 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6957 *= _5383.y;\n            _6958 *= _5383.z;\n            _6960 *= _5372.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6961 *= mrt.x;\n            _6963 *= mrt.w;\n        }\n    }\n    return Surface(_5276.xyz, _5276.w, _6952, clamp(fa_mesh_fs_params[5].x * _5344.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5344.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5383.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5413), _6957, _6958, fa_mesh_fs_params[21].xyz, _6960, _6961, fa_mesh_fs_params[20].w, _6963, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1657 = rect.zw - rect.xy;\n    vec2 _1661 = _1657 * atlas;\n    vec2 _1665 = ddx * _1661;\n    vec2 _1669 = ddy * _1661;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1657), clamp(0.5 * log2(max(max(dot(_1665, _1665), dot(_1669, _1669)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1702 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1709;\n    if (!_1702)\n    {\n        _1709 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1709 = _1702;\n    }\n    if (_1709)\n    {\n        return;\n    }\n    vec3 _1715 = dFdx(world_pos);\n    vec3 _1718 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1722 = fa_cluster_texel(param);\n    int _1726 = int(_1722.w);\n    if (_1726 < 1)\n    {\n        return;\n    }\n    int _1736 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1736;\n    vec4 _1740 = fa_light_texel(param_1);\n    vec2 _1743 = _1740.yz;\n    int _1747 = int(_1740.w);\n    int param_2 = _1736 + 1;\n    vec4 _1752 = fa_light_texel(param_2);\n    float _1753 = _1752.x;\n    int _1759 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1763 = int(_1722.z);\n    vec3 _2028;\n    for (int k = 0; k < _1726; k++)\n    {\n        int _1776 = _1763 + k;\n        int param_3 = _1747 + (_1776 >> 2);\n        int _1793 = (_1736 + 2) + (int(fa_light_texel(param_3)[_1776 & 3]) * 7);\n        int param_4 = _1793 + 6;\n        vec4 _1798 = fa_light_texel(param_4);\n        if (((int(_1798.w + 0.5) >> _1759) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1793;\n        vec4 _1813 = fa_light_texel(param_5);\n        int param_6 = _1793 + 1;\n        vec4 _1818 = fa_light_texel(param_6);\n        int param_7 = _1793 + 2;\n        vec4 _1823 = fa_light_texel(param_7);\n        vec3 _1826 = _1813.xyz;\n        float _1831 = dot(_1826, world_pos) + _1813.w;\n        vec3 _1833 = _1818.xyz;\n        float _1838 = dot(_1833, world_pos) + _1818.w;\n        vec3 _1840 = _1823.xyz;\n        float _1845 = dot(_1840, world_pos) + _1823.w;\n        bool _1850 = abs(_1831) > 0.5;\n        bool _1858;\n        if (!_1850)\n        {\n            _1858 = abs(_1838) > 0.5;\n        }\n        else\n        {\n            _1858 = _1850;\n        }\n        bool _1866;\n        if (!_1858)\n        {\n            _1866 = abs(_1845) > 0.5;\n        }\n        else\n        {\n            _1866 = _1858;\n        }\n        if (_1866)\n        {\n            continue;\n        }\n        float _1881 = clamp(dot(geo_normal, normalize(_1840)) * _1798.z, 0.0, 1.0);\n        if (_1881 <= 0.0)\n        {\n            continue;\n        }\n        float _1901 = (clamp((0.5 - abs(_1845)) * 10.0, 0.0, 1.0) * _1881) * _1798.x;\n        vec2 _1909 = vec2(_1831 + 0.5, 0.5 - _1838);\n        vec2 _1919 = vec2(dot(_1826, _1715), dot(_1833, _1715));\n        vec2 _1929 = vec2(dot(_1826, _1718), dot(_1833, _1718));\n        int param_8 = _1793 + 5;\n        vec4 _1934 = fa_light_texel(param_8);\n        int param_9 = _1793 + 3;\n        vec4 _1939 = fa_light_texel(param_9);\n        int param_10 = _1793 + 4;\n        vec4 _1944 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1934.xyz;\n        bool _1954 = _1939.z > _1939.x;\n        if (_1954)\n        {\n            vec4 param_11 = _1939;\n            vec2 param_12 = _1909;\n            vec2 param_13 = _1743;\n            vec2 param_14 = _1919;\n            vec2 param_15 = _1929;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1753 > 0.5) && (_1753 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1980 = fa_dc_to_linear(param_16);\n                vec4 _7040 = tx;\n                _7040.x = _1980.x;\n                _7040.y = _1980.y;\n                _7040.z = _1980.z;\n                tx = _7040;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1901 * tex_a) * _1934.w, 0.0, 1.0)));\n        if (_1944.z > _1944.x)\n        {\n            vec4 param_17 = _1944;\n            vec2 param_18 = _1909;\n            vec2 param_19 = _1743;\n            vec2 param_20 = _1919;\n            vec2 param_21 = _1929;\n            vec4 _2024 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1753 > 1.5)\n            {\n                vec3 param_22 = _2024.xyz;\n                vec3 _2034 = fa_dc_to_srgb(param_22);\n                _2028 = _2034;\n            }\n            else\n            {\n                _2028 = _2024.xyz;\n            }\n            vec3 _2043 = (_2028 * 2.0) - vec3(1.0);\n            vec2 _2048 = _2043.xy * _1798.y;\n            vec3 _2070 = (normalize(_1826) * _2048.x) + (normalize(_1833) * _2048.y);\n            vec3 _2073 = normalize(normal);\n            normal = normalize(mix(_2073, normalize((_2073 * max(_2043.z, 0.0500000007450580596923828125)) + (_2070 - (_2073 * dot(_2073, _2070)))), vec3(clamp(_1901 * (_1954 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3281 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3281;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3894 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3899 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3894 > 0.0005000000237487256526947021484375)\n    {\n        if (_3899)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3894;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3894;\n        }\n    }\n    bool _3950 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3950)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3981 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3981)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3899 || _3950) || _3981)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3301 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3304 = _3301.x;\n    float _3306 = _3301.z;\n    vec2 e = vec2(_3304, _3306);\n    if (_3301.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3306)) * ((_3304 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3304)) * ((_3306 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _5525 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _5530 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _5535 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _5540 = fa_light_texel(param_3);\n    bool _5543 = _5540.z < 0.5;\n    bool _5551;\n    if (!_5543)\n    {\n        _5551 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _5551 = _5543;\n    }\n    if (_5551)\n    {\n        return vec3(0.0);\n    }\n    float _5558 = max(_5525.w, 9.9999997473787516355514526367188e-05);\n    vec3 _5561 = _5530.xyz;\n    vec3 _5565 = _5525.xyz;\n    vec3 _5569 = (fa_world_pos - _5565) / vec3(_5558);\n    vec3 _5578 = min(_5569 + vec3(0.5), (_5561 - vec3(0.5)) - _5569);\n    float _5587 = min(_5578.x, min(_5578.y, _5578.z));\n    if (!(_5587 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5602 = _5561 - vec3(1.0);\n    vec3 _5603 = clamp(_5569, vec3(0.0), _5602);\n    vec3 _5611 = min(floor(_5603), max(_5561 - vec3(2.0), vec3(0.0)));\n    vec3 _5615 = _5603 - _5611;\n    vec3 _5626 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _5558));\n    int _5631 = int(_5535.y + 0.5);\n    float _5636 = 0.3257350027561187744140625 * n.y;\n    float _5640 = 0.3257350027561187744140625 * n.z;\n    float _5644 = 0.3257350027561187744140625 * n.x;\n    float _5651 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _5658 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _5667 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _5674 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _5687 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _5694 = 8 + int(_5540.w);\n    float _5721;\n    float _5734;\n    float _5748;\n    for (int k = 0; k < _5694; k++)\n    {\n        float _5707 = float(k & 1);\n        float _5711 = float((k >> 1) & 1);\n        float _5715 = float((k >> 2) & 1);\n        if (_5707 > 0.5)\n        {\n            _5721 = _5615.x;\n        }\n        else\n        {\n            _5721 = 1.0 - _5615.x;\n        }\n        if (_5711 > 0.5)\n        {\n            _5734 = _5615.y;\n        }\n        else\n        {\n            _5734 = 1.0 - _5615.y;\n        }\n        if (_5715 > 0.5)\n        {\n            _5748 = _5615.z;\n        }\n        else\n        {\n            _5748 = 1.0 - _5615.z;\n        }\n        float _5758 = (_5721 * _5734) * _5748;\n        if (!(_5758 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5771 = min(_5611 + vec3(_5707, _5711, _5715), _5602);\n        int _5791 = int(((_5535.x + _5771.x) + (_5530.x * (_5771.y + (_5530.y * _5771.z)))) + 0.5);\n        vec2 _5806 = vec2(float(_5791 % _5631) * 10.0, 1024.0 + (float(_5791 / _5631) * 11.0));\n        vec2 param_4 = _5806 + vec2(9.5, 10.5);\n        vec4 _5814 = fa_gi_fetch(param_4);\n        bool _5817 = _5814.y < 0.5;\n        bool _5826;\n        if (!_5817)\n        {\n            _5826 = _5814.x > _5540.y;\n        }\n        else\n        {\n            _5826 = _5817;\n        }\n        if (_5826)\n        {\n            continue;\n        }\n        vec3 _5838 = _5626 - (_5565 + (_5771 * _5558));\n        float _5841 = length(_5838);\n        vec3 _5847 = _5838 / vec3(max(_5841, 9.9999997473787516355514526367188e-05));\n        float _5857 = max(9.9999997473787516355514526367188e-05, (dot(-_5847, n) + 1.0) * 0.5);\n        float w = _5758 * (_5857 * _5857);\n        vec3 param_5 = _5847;\n        vec2 param_6 = (_5806 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5876 = fa_gi_fetch(param_6);\n        float _5883 = _5841 / max(_5535.z, 9.9999997473787516355514526367188e-05);\n        float _5886 = _5876.x;\n        if (_5883 > _5886)\n        {\n            float _5899 = max(_5876.y - (_5886 * _5886), 0.0);\n            float _5904 = _5883 - _5886;\n            float _5913 = _5899 / max(_5899 + (_5904 * _5904), 9.9999999600419720025001879548654e-13);\n            w *= ((_5913 * _5913) * _5913);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5806 + vec2(0.5, 10.5);\n        vec2 param_8 = _5806 + vec2(1.5, 10.5);\n        vec2 param_9 = _5806 + vec2(2.5, 10.5);\n        vec2 param_10 = _5806 + vec2(3.5, 10.5);\n        vec2 param_11 = _5806 + vec2(4.5, 10.5);\n        vec2 param_12 = _5806 + vec2(5.5, 10.5);\n        vec2 param_13 = _5806 + vec2(6.5, 10.5);\n        vec2 param_14 = _5806 + vec2(7.5, 10.5);\n        vec2 param_15 = _5806 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _5636)) + (fa_gi_fetch(param_9).xyz * _5640)) + (fa_gi_fetch(param_10).xyz * _5644)) + (fa_gi_fetch(param_11).xyz * _5651)) + (fa_gi_fetch(param_12).xyz * _5658)) + (fa_gi_fetch(param_13).xyz * _5667)) + (fa_gi_fetch(param_14).xyz * _5674)) + (fa_gi_fetch(param_15).xyz * _5687)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_5587 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6039;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6039 = _5540.x;\n    }\n    else\n    {\n        _6039 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_5535.w * _6039);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6063 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6068 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6073 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6073) && (k < 8); k++)\n    {\n        int param = _6068 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6063;\n        vec3 _6098 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6103 = param_3 * left;\n        acc += (_6098 * _6103);\n        left -= _6103;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6132 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6132;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4113 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4121 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4124 = int(_4113);\n    int _4127 = int(_4121);\n    float _4137 = _4121 - float(_4127);\n    int _4192 = (_4124 * 9) + _4127;\n    int _4212 = ((_4124 + 1) * 9) + _4127;\n    return mix(mix(_4188[_4192], _4188[_4192 + 1], _4137), mix(_4188[_4212], _4188[_4212 + 1], _4137), _4113 - float(_4124));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6811 = false;\n    float _6812 = 1.0;\n    float _6813 = 1.0;\n    float _6814 = 1.0;\n    float _6815 = 0.0;\n    float _6816 = 0.0;\n    float _6817 = 0.0;\n    float _6818 = 0.0;\n    float _6820 = 1.0;\n    bool _6821 = false;\n    vec3 _6822 = vec3(0.0);\n    float _6823 = 1.0;\n    float _6824 = 1.0;\n    float _6825 = 1.0;\n    float _6826 = 0.0;\n    float _6827 = 0.0;\n    vec3 _6828 = vec3(1.0, 0.0, 0.0);\n    vec3 _6829 = vec3(0.0, 0.0, 1.0);\n    float _6830 = 1.0;\n    float _6831 = 1.0;\n    float _4263 = clamp(s.specular, 0.0, 1.0);\n    float _4267 = clamp(s.ior, 1.0, 3.0);\n    bool _4272 = (_4263 != 1.0) || (_4267 != 1.5);\n    bool _4281;\n    if (!_4272)\n    {\n        _4281 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4281 = _4272;\n    }\n    if (_4281)\n    {\n        float _4289 = (_4267 - 1.0) / (_4267 + 1.0);\n        f0 = mix(min(vec3(_4289 * _4289) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4263, s.albedo, vec3(metallic));\n        _6812 = mix(_4263, 1.0, metallic);\n        _6811 = true;\n    }\n    float _4316 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4316 > 0.0)\n    {\n        float _4324 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6815 = _4316;\n        _6816 = _4324;\n        float _4331 = _4324 * _4324;\n        _6817 = _4331;\n        _6818 = _4331 * _4331;\n        float _4343 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6820 = _4343;\n        _6813 = 1.0 - (_4316 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4343, 0.0, 1.0), 5.0))));\n        _6811 = true;\n    }\n    vec3 _4362 = max(s.sheen_color, vec3(0.0));\n    float _4371 = max(_4362.x, max(_4362.y, _4362.z));\n    if (_4371 > 0.0)\n    {\n        float _4379 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6821 = true;\n        _6822 = _4362;\n        _6823 = _4379;\n        _6824 = _4379 * _4379;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4379;\n        float _4396 = fa_sheen_albedo(param, param_1);\n        _6826 = _4396;\n        _6825 = 1.0 - min(_4371 * _4396, 1.0);\n        _6811 = true;\n    }\n    _6814 = _6813 * _6825;\n    float _4415 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4415 != 0.0)\n    {\n        vec3 _4430 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4430;\n        if (dot(_4430, _4430) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4442 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4442.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4442.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4442.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4446 = t;\n        vec3 _4447 = normalize(_4446);\n        t = _4447;\n        vec3 _4472 = normalize((_4447 * cos(s.anisotropy_rotation)) + ((cross(n, _4447) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6828 = _4472;\n        _6829 = cross(n, _4472);\n        float _4482 = roughness * roughness;\n        float _4488 = mix(_4482, 1.0, _4415 * _4415);\n        bool _4490 = _4415 > 0.0;\n        _6830 = _4490 ? _4488 : _4482;\n        _6831 = _4490 ? _4482 : _4488;\n        _6827 = _4415;\n        _6811 = true;\n    }\n    return FaLayers(_6811, _6812, _6813, _6814, _6815, _6816, _6817, _6818, i.world_normal, _6820, _6821, _6822, _6823, _6824, _6825, _6826, _6827, _6828, _6829, _6830, _6831);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4045 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4048 = _4045.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4048 * _4048, exp2((-9.27999973297119140625) * ndv)) * _4048) + _4045.y)) + _4045.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3353;\n    if (lv == 0)\n    {\n        _3353 = 0.0;\n    }\n    else\n    {\n        _3353 = res + 2.0;\n    }\n    float _3363;\n    if (lv == 0)\n    {\n        _3363 = 0.0;\n    }\n    else\n    {\n        _3363 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3353, _3363)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3409;\n    if (res > 64.5)\n    {\n        _3409 = 5.0;\n    }\n    else\n    {\n        _3409 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3424 = clamp(rough, 0.0, 1.0) * (_3409 - 1.0);\n    int _3431 = int(min(floor(_3424), _3409 - 2.0));\n    float _3436 = _3424 - float(_3431);\n    vec3 param = d;\n    vec2 _3440 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3431;\n    vec2 param_4 = _3440;\n    vec3 _3450 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3436 < 0.00200000009499490261077880859375)\n    {\n        return _3450;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3431 + 1;\n    vec2 param_8 = _3440;\n    return mix(_3450, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3436));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3523 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3530 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3537 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3543 = dot(bx.xyz, d);\n    float _3547 = dot(by.xyz, d);\n    float _3551 = dot(bz.xyz, d);\n    float _3557;\n    if (_3543 > 9.9999999747524270787835121154785e-07)\n    {\n        _3557 = (1.0 - _3523) / _3543;\n    }\n    else\n    {\n        float _3571;\n        if (_3543 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3571 = ((-1.0) - _3523) / _3543;\n        }\n        else\n        {\n            _3571 = 1000000015047466219876688855040.0;\n        }\n        _3557 = _3571;\n    }\n    float tx = _3557;\n    float _3588;\n    if (_3547 > 9.9999999747524270787835121154785e-07)\n    {\n        _3588 = (1.0 - _3530) / _3547;\n    }\n    else\n    {\n        float _3601;\n        if (_3547 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3601 = ((-1.0) - _3530) / _3547;\n        }\n        else\n        {\n            _3601 = 1000000015047466219876688855040.0;\n        }\n        _3588 = _3601;\n    }\n    float ty = _3588;\n    float _3617;\n    if (_3551 > 9.9999999747524270787835121154785e-07)\n    {\n        _3617 = (1.0 - _3537) / _3551;\n    }\n    else\n    {\n        float _3630;\n        if (_3551 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3630 = ((-1.0) - _3537) / _3551;\n        }\n        else\n        {\n            _3630 = 1000000015047466219876688855040.0;\n        }\n        _3617 = _3630;\n    }\n    float _3642 = tx;\n    float _3645 = (_3642 > 0.0) ? _3642 : 1000000015047466219876688855040.0;\n    tx = _3645;\n    float _3646 = ty;\n    float _3649 = (_3646 > 0.0) ? _3646 : 1000000015047466219876688855040.0;\n    ty = _3649;\n    float _3659 = min(_3645, min(_3649, (_3617 > 0.0) ? _3617 : 1000000015047466219876688855040.0));\n    if (_3659 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3675 = (fa_world_pos + (d * _3659)) - posw.xyz;\n    vec3 _3680;\n    if (dot(_3675, _3675) > 1.0000000133514319600180897396058e-10)\n    {\n        _3680 = normalize(_3675);\n    }\n    else\n    {\n        _3680 = d;\n    }\n    return _3680;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3726 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3726 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3754 = rough * rough;\n            float _3785 = 0.60000002384185791015625 * _3754;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3754)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3785, 0.0500000007450580596923828125 + _3785, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3754 * 0.60000002384185791015625));\n        }\n        outc = base * _3726;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3844 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3844 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3876 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3876 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4523;\n        if (L.aniso >= 0.0)\n        {\n            _4523 = L.b;\n        }\n        else\n        {\n            _4523 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4523, v), _4523), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4559 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4559.x) + (vec3(L.f90) * _4559.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4617 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4617.x) + _4617.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4087 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4087.x) + vec3(_4087.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4646 = clamp(s.metallic, 0.0, 1.0);\n    float _4650 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4657 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4646));\n    vec3 f0 = _4657;\n    vec3 _4661 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4661;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4646;\n    float param_5 = _4650;\n    vec3 param_6 = _4657;\n    FaLayers _4678 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4678.on)\n    {\n        FaLayers param_7 = _4678;\n        vec3 param_8 = _4661;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4650;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4661;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4650;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4981;\n    if (fa_lm.z > 0.5)\n    {\n        _4981 = 0.0;\n    }\n    else\n    {\n        _4981 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4992 = _4981 < 1.0;\n    bool _4998;\n    if (_4992)\n    {\n        int param = li;\n        _4998 = fa_light_baked(param);\n    }\n    else\n    {\n        _4998 = _4992;\n    }\n    return _4998 ? _4981 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _676 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _689 = (c - (ru * hx)) - p;\n        vec3 _695 = ru * (2.0 * hx);\n        float _701 = max(dot(_695, _695), 9.9999999392252902907785028219223e-09);\n        float _705 = dot(_689, _695);\n        float t = clamp((-_705) / _701, 0.0, 1.0);\n        if (_676)\n        {\n            float _720 = dot(r, _695);\n            float _726 = _701 - (_720 * _720);\n            if (abs(_726) > (9.9999997473787516355514526367188e-06 * _701))\n            {\n                t = clamp(((dot(r, _689) * _720) - _705) / _726, 0.0, 1.0);\n            }\n        }\n        return (p + _689) + (_695 * t);\n    }\n    vec3 q = p;\n    float _758 = dot(r, axis);\n    bool _766;\n    if (_676)\n    {\n        _766 = abs(_758) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _766 = _676;\n    }\n    if (_766)\n    {\n        float _776 = dot(c - p, axis) / _758;\n        if (_776 > 0.0)\n        {\n            q = p + (r * _776);\n        }\n    }\n    vec3 _789 = q - c;\n    vec2 xy = vec2(dot(_789, ru), dot(_789, uu));\n    if (shape > 0.5)\n    {\n        float _804 = length(xy);\n        if (_804 > hx)\n        {\n            xy *= (hx / _804);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10)\n    {\n        _611 = atan(_600, _596) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _611 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_611 - floor(_611)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _446 = abs(d);\n    float _448 = _446.x;\n    float _450 = _446.y;\n    bool _451 = _448 >= _450;\n    bool _459;\n    if (_451)\n    {\n        _459 = _448 >= _446.z;\n    }\n    else\n    {\n        _459 = _451;\n    }\n    int _460;\n    if (_459)\n    {\n        _460 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _475;\n        if (_450 >= _446.z)\n        {\n            _475 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _475 = (d.z > 0.0) ? 4 : 5;\n        }\n        _460 = _475;\n    }\n    return _460;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _842 = fa_light_base(param);\n    bool _846 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _842;\n    vec4 _850 = fa_light_texel(param_1);\n    int param_2 = _842 + 1;\n    vec4 _855 = fa_light_texel(param_2);\n    float _858 = _855.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _870 = _846 && (_858 > 2.5);\n    fa_light_is_area = _870;\n    bool _872 = _858 < 0.5;\n    vec3 l;\n    if (_872)\n    {\n        l = normalize(_850.xyz);\n        if (_846)\n        {\n            int param_3 = _842 + 6;\n            vec4 _886 = fa_light_texel(param_3);\n            if (_886.z > 0.5)\n            {\n                int param_4 = _842 + 4;\n                vec4 _896 = fa_light_texel(param_4);\n                int param_5 = _842 + 5;\n                vec4 _901 = fa_light_texel(param_5);\n                vec2 param_6 = _886.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _896.xyz) * _896.w, (-dot(world_pos, _901.xyz)) * _901.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _931 = _850.xyz;\n        vec3 _933 = _931 - world_pos;\n        vec3 to_light = _933;\n        float _936 = length(_933);\n        float reach = _936;\n        bool front = true;\n        if (_870)\n        {\n            int param_8 = _842 + 7;\n            reach = max(_936 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _842 + 4;\n            vec4 _960 = fa_light_texel(param_9);\n            int param_10 = _842 + 5;\n            vec4 _965 = fa_light_texel(param_10);\n            int param_11 = _842 + 6;\n            vec4 _970 = fa_light_texel(param_11);\n            float _971 = _970.w;\n            int param_12 = _842 + 2;\n            vec3 _978 = normalize(fa_light_texel(param_12).xyz);\n            bool _980 = _971 > 1.5;\n            bool _988;\n            if (!_980)\n            {\n                _988 = dot(_978, to_light) < 0.0;\n            }\n            else\n            {\n                _988 = _980;\n            }\n            front = _988;\n            vec3 r = vec3(0.0);\n            vec3 _997 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1001 = dot(n, n) > 0.5;\n            bool _1009;\n            if (_1001)\n            {\n                _1009 = dot(_997, _997) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1009 = _1001;\n            }\n            if (_1009)\n            {\n                r = reflect(-normalize(_997), normalize(n));\n            }\n            vec3 param_13 = _931;\n            vec3 param_14 = _978;\n            vec3 param_15 = _960.xyz;\n            vec3 param_16 = _965.xyz;\n            float param_17 = _960.w;\n            float param_18 = _965.w;\n            float param_19 = _971;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1045 = length(to_light);\n        dist = _1045;\n        l = to_light / vec3(max(_1045, 9.9999997473787516355514526367188e-05));\n        float _1059 = reach / max(_850.w, 0.001000000047497451305389404296875);\n        float _1065 = clamp(1.0 - (_1059 * _1059), 0.0, 1.0);\n        float _1067;\n        if (front)\n        {\n            _1067 = _1065 * _1065;\n        }\n        else\n        {\n            _1067 = 0.0;\n        }\n        atten = _1067;\n        bool _1078 = _858 < 2.5;\n        if ((_858 > 1.5) && _1078)\n        {\n            int param_22 = _842 + 2;\n            vec4 _1086 = fa_light_texel(param_22);\n            float _1096 = _1086.w;\n            int param_23 = _842 + 3;\n            vec4 _1101 = fa_light_texel(param_23);\n            float _1102 = _1101.x;\n            float cos_inner = _1102;\n            if (_1102 > 1.5)\n            {\n                cos_inner = mix(_1096, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1096, cos_inner, dot(-l, normalize(_1086.xyz)));\n        }\n        if (_846 && (_858 < 1.5))\n        {\n            int param_24 = _842 + 6;\n            vec4 _1126 = fa_light_texel(param_24);\n            if (_1126.z > 0.5)\n            {\n                vec3 _1134 = -to_light;\n                int param_25 = _842 + 4;\n                int param_26 = _842 + 5;\n                vec3 _1148 = fa_light_texel(param_25).xyz;\n                vec3 _1152 = fa_light_texel(param_26).xyz;\n                vec3 _1161 = vec3(dot(_1134, _1148), dot(_1134, _1152), dot(_1134, cross(_1148, _1152)));\n                vec3 param_27 = _1161;\n                int _1165 = fa_cube_face(param_27);\n                int param_28 = _1165;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1192 = vec2(dot(_1161, cross(param_29, param_30)), dot(_1161, param_30)) / vec2(max(dot(_1161, param_29), 9.9999997473787516355514526367188e-05));\n                int _1196 = _1165 / 3;\n                vec2 param_31 = _1126.xy + (vec2(float(_1165 - (_1196 * 3)), float(_1196)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1192.x), 0.5 - (0.5 * _1192.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _842 + 7;\n            vec4 _1226 = fa_light_texel(param_33);\n            if (_1226.z > 0.5)\n            {\n                int param_34 = _842 + 2;\n                int param_35 = _842 + 4;\n                int param_36 = _842 + 5;\n                vec2 param_37 = _1226.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_846 && _1078)\n            {\n                int param_42 = _842 + 6;\n                vec4 _1273 = fa_light_texel(param_42);\n                int param_43 = _842 + 7;\n                vec4 _1278 = fa_light_texel(param_43);\n                bool _1281 = _1273.z > 0.5;\n                bool _1288;\n                if (!_1281)\n                {\n                    _1288 = _1278.z > 0.5;\n                }\n                else\n                {\n                    _1288 = _1281;\n                }\n                if (_1288)\n                {\n                    int param_44 = _842 + 2;\n                    vec4 _1295 = fa_light_texel(param_44);\n                    vec3 _1299 = normalize(_1295.xyz);\n                    int param_45 = _842 + 4;\n                    vec4 _1304 = fa_light_texel(param_45);\n                    int param_46 = _842 + 5;\n                    vec4 _1309 = fa_light_texel(param_46);\n                    if (_1281)\n                    {\n                        vec3 _1317 = -to_light;\n                        float _1324 = _1295.w;\n                        float _1340 = 0.5 / max(dot(_1317, _1299) * (sqrt(max(1.0 - (_1324 * _1324), 0.0)) / max(_1324, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1273.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1317, _1304.xyz) * _1340), 0.5 - (dot(_1317, _1309.xyz) * _1340));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1278.z > 0.5)\n                    {\n                        vec2 param_49 = _1278.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1299;\n                        vec3 param_52 = _1304.xyz;\n                        vec3 param_53 = _1309.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6799 = _855.xyz * atten;\n    if (_846)\n    {\n        _6799 *= fa_light_tint;\n    }\n    int _1408;\n    if (_872)\n    {\n        _1408 = 0;\n    }\n    else\n    {\n        _1408 = ((_858 > 1.5) && (_858 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6799, atten, 1.0, dist, _1408);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2197 = fa_shadow_depth(param, param_1);\n    float _2201;\n    if (conv.x < 0.5)\n    {\n        _2201 = _2197;\n    }\n    else\n    {\n        _2201 = (conv.y * conv.z) / (conv.z - (_2197 * (conv.z - conv.y)));\n    }\n    return _2201;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2247 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2253 = vec2(cos(_2247), sin(_2247));\n    vec2 dir = _2253;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2262;\n        if (k < 0.0)\n        {\n            _2262 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2262 = k;\n        }\n        float _2281 = clamp((_2262 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2300 = sqrt((float(i) + 0.5) * 0.0625) * _2281;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2300));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2314 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2314 < (zr - (_2300 * plane)))\n            {\n                sum += _2314;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2342 = sum / cnt;\n        float _2352;\n        if (k < 0.0)\n        {\n            _2352 = (-k) / max(_2342, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2352 = k;\n        }\n        radius = clamp(((max(zr - _2342, 0.0) * unit) * _2352) / texel_m, 1.5, 16.0);\n        dir = _2253;\n    }\n    float lit = 0.0;\n    int _2378 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2378; i_1++)\n    {\n        float _2397 = sqrt((float(i_1) + 0.5) / float(_2378)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2397));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2397 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2378);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2602 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2609;\n    if (!_2602)\n    {\n        _2609 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2609 = _2602;\n    }\n    if (_2609)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2622 = fa_light_texel(param);\n    float _2623 = _2622.x;\n    if (_2623 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2632 = int(_2623 + 0.5);\n    int param_1 = _2632;\n    vec4 _2636 = fa_light_texel(param_1);\n    int param_2 = _2632 + 1;\n    vec4 _2641 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2644 = _2636.y;\n    if (_2644 > 0.0)\n    {\n        float _2661 = 1.0 - smoothstep(0.75 * _2644, _2644, length(world - fa_shadows[27].xyz));\n        fade = _2661;\n        if (_2661 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2636.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2685 = (_2632 + 2) + (face * 6);\n    int param_4 = _2685;\n    int param_5 = _2685 + 1;\n    int param_6 = _2685 + 3;\n    vec4 _2699 = fa_light_texel(param_6);\n    int param_7 = _2685 + 4;\n    vec4 _2704 = fa_light_texel(param_7);\n    int param_8 = _2685 + 5;\n    vec4 _2709 = fa_light_texel(param_8);\n    float _2721 = _2709.x * max(dot(_2699, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2726 = clamp(dot(n, l), 0.0, 1.0);\n    float _2749 = clamp(dot(n, _2699.xyz), -1.0, 1.0);\n    float _2768 = min(sqrt(1.0 - (_2749 * _2749)) / max(abs(dot(n, world - lpos)) / max(dot(_2699, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2771 = _2641.y;\n    float _2773;\n    if (_2771 > 0.0)\n    {\n        _2773 = _2771;\n    }\n    else\n    {\n        _2773 = 1.5 * _2721;\n    }\n    vec4 _2793 = vec4(world + (n * (_2773 * sqrt(1.0 - (_2726 * _2726)))), 1.0);\n    float _2797 = dot(_2699, _2793);\n    float _2800 = _2709.y;\n    if (_2797 < _2800)\n    {\n        return 1.0;\n    }\n    vec2 _2815 = vec2(dot(fa_light_texel(param_4), _2793), dot(fa_light_texel(param_5), _2793)) / vec2(_2797);\n    float _2817 = _2815.x;\n    bool _2820 = _2817 < _2704.x;\n    bool _2829;\n    if (!_2820)\n    {\n        _2829 = _2817 > _2704.z;\n    }\n    else\n    {\n        _2829 = _2820;\n    }\n    bool _2838;\n    if (!_2829)\n    {\n        _2838 = _2815.y < _2704.y;\n    }\n    else\n    {\n        _2838 = _2829;\n    }\n    bool _2847;\n    if (!_2838)\n    {\n        _2847 = _2815.y > _2704.w;\n    }\n    else\n    {\n        _2847 = _2838;\n    }\n    if (_2847)\n    {\n        return 1.0;\n    }\n    float _2853 = _2641.x;\n    float _2855;\n    if (_2853 > 0.0)\n    {\n        _2855 = _2853;\n    }\n    else\n    {\n        _2855 = 1.5 * _2721;\n    }\n    vec2 param_9 = _2815;\n    vec4 param_10 = _2704;\n    float param_11 = _2797 - (_2855 * (1.0 + (0.5 * _2768)));\n    float param_12 = _2721;\n    float param_13 = 1.0;\n    float param_14 = _2709.z * 0.25;\n    float param_15 = (_2721 * min(_2768, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2800, _2709.z);\n    int param_17 = int(_2636.z + 0.5);\n    float param_18 = _2636.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2140;\n    if (i == 0)\n    {\n        _2140 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2156;\n        if (i == 1)\n        {\n            _2156 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2164;\n            if (i == 2)\n            {\n                _2164 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2164 = fa_shadows[24].w;\n            }\n            _2156 = _2164;\n        }\n        _2140 = _2156;\n    }\n    return _2140;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2443 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2448 = clamp(dot(n, l), 0.0, 1.0);\n    float _2454 = sqrt(1.0 - (_2448 * _2448));\n    float _2462 = min(_2454 / max(_2448, 0.20000000298023223876953125), 4.0);\n    float _2467;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2467 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2467 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2492 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2467 * _2454)), 1.0);\n    float _2499 = _2492.x;\n    bool _2502 = _2499 < fa_shadows[ci * 1 + 16].x;\n    bool _2511;\n    if (!_2502)\n    {\n        _2511 = _2499 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2511 = _2502;\n    }\n    bool _2520;\n    if (!_2511)\n    {\n        _2520 = _2492.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2520 = _2511;\n    }\n    bool _2529;\n    if (!_2520)\n    {\n        _2529 = _2492.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2529 = _2520;\n    }\n    bool _2536;\n    if (!_2529)\n    {\n        _2536 = _2492.z > 1.0;\n    }\n    else\n    {\n        _2536 = _2529;\n    }\n    if (_2536)\n    {\n        return -1.0;\n    }\n    float _2544;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2544 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2544 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2492.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2492.z - ((_2544 * (1.0 + (0.5 * _2462))) / _2443);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2443;\n    float param_5 = _2443 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2462, 3.0)) * 0.5) / _2443;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2922 = int(fa_shadows[25].x + 0.5);\n    if (_2922 < 1)\n    {\n        return 1.0;\n    }\n    float _2937 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2922 - 1;\n    if (_2937 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2949 = _2922 > 1;\n    bool _2956;\n    if (_2949)\n    {\n        _2956 = _2937 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2956 = _2949;\n    }\n    if (_2956)\n    {\n        ci = 1;\n    }\n    bool _2960 = _2922 > 2;\n    bool _2967;\n    if (_2960)\n    {\n        _2967 = _2937 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2967 = _2960;\n    }\n    if (_2967)\n    {\n        ci = 2;\n    }\n    bool _2971 = _2922 > 3;\n    bool _2978;\n    if (_2971)\n    {\n        _2978 = _2937 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2978 = _2971;\n    }\n    if (_2978)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2922)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3004 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3004;\n        if (_3004 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3029;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3029 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3029 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3048 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3029, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3059 = clamp((_2937 - (fa_shadow_split_at(param_7) - _3048)) / _3048, 0.0, 1.0);\n        if (_3059 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2922)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3080 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3080;\n                if (_3080 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3059);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4717 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4724;\n    if (!_4717)\n    {\n        _4724 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4724 = _4717;\n    }\n    if (_4724)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4737 = fa_light_texel(param);\n    float _4738 = _4737.y;\n    float len = _4738;\n    if (_4738 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4750 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4760 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4750);\n    if (_4760 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4766 = len;\n    float _4769 = min(_4766, 0.89999997615814208984375 * dist);\n    len = _4769;\n    float _4774 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4750);\n    float _4779 = _4774 + (0.5 * _4769);\n    vec3 _4785 = world + (gn * _4774);\n    float _4787 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4851;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4802 = (float(k) + _4787) * 0.083333335816860198974609375;\n        vec3 _4810 = _4785 + (l * (_4802 * len));\n        vec4 _4816 = vec4(_4810, 1.0);\n        float _4822 = dot(fa_mesh_fs_params[28], _4816);\n        if (_4822 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4842 = vec2(dot(fa_mesh_fs_params[26], _4816), dot(fa_mesh_fs_params[27], _4816)) / vec2(_4822);\n        float _4846 = _4842.x * 0.5;\n        float _4847 = _4846 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4851 = (_4842.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4851 = 0.5 - (_4842.y * 0.5);\n        }\n        bool _4867 = _4847 < 0.0;\n        bool _4874;\n        if (!_4867)\n        {\n            _4874 = _4847 >= 1.0;\n        }\n        else\n        {\n            _4874 = _4867;\n        }\n        bool _4881;\n        if (!_4874)\n        {\n            _4881 = _4851 < 0.0;\n        }\n        else\n        {\n            _4881 = _4874;\n        }\n        bool _4888;\n        if (!_4881)\n        {\n            _4888 = _4851 >= 1.0;\n        }\n        else\n        {\n            _4888 = _4881;\n        }\n        if (_4888)\n        {\n            break;\n        }\n        vec4 _4915 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4847, _4851) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4915.w < 0.5)\n        {\n            continue;\n        }\n        float _4934 = (dot(fa_mesh_fs_params[29].xyz, _4810) + fa_mesh_fs_params[29].w) - _4915.x;\n        if ((_4934 > _4774) && (_4934 < _4779))\n        {\n            occ = max(occ, (1.0 - (_4802 * _4802)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4847, 0.5 - _4846), min(_4851, 1.0 - _4851))));\n        }\n    }\n    return 1.0 - (occ * _4760);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5037 = fa_baked_keep(param);\n    if (_5037 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5063 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6932 = _5063.color;\n    float _6933 = _5063.attenuation;\n    float _6934 = _5063.shadow;\n    bool _5066 = _5063.type == 0;\n    if (_5066 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5063.direction;\n        float _5077 = fa_shadow_factor(param_5, param_6);\n        _6934 = _5077;\n        _6932 *= _5077;\n    }\n    else\n    {\n        bool _5088 = _5063.type != 0;\n        bool _5094;\n        if (_5088)\n        {\n            _5094 = _6933 > 0.0;\n        }\n        else\n        {\n            _5094 = _5088;\n        }\n        if (_5094)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5063.direction;\n            float _5113 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6934 = _5113;\n            _6932 *= _5113;\n        }\n    }\n    bool _5123 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5129;\n    if (_5123)\n    {\n        _5129 = _6933 > 0.0;\n    }\n    else\n    {\n        _5129 = _5123;\n    }\n    if (_5129)\n    {\n        float _5136;\n        if (_5066)\n        {\n            _5136 = 1000000000.0;\n        }\n        else\n        {\n            _5136 = _5063._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5063.direction;\n        float param_18 = _5136;\n        float _5154 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6934 *= _5154;\n        _6932 *= _5154;\n    }\n    float _5167 = _6933;\n    float _5168 = _5167 * _5037;\n    _6933 = _5168;\n    vec3 _5172 = _6932;\n    vec3 _5173 = _5172 * _5037;\n    _6932 = _5173;\n    return LightSample(_5063.direction, _5173, _5168, _6934, _5063._distance, _5063.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3104 = int(fa_shadows[25].x + 0.5);\n    float _3114 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3119 = _3104 > 0;\n    bool _3128;\n    if (_3119)\n    {\n        int param = _3104 - 1;\n        _3128 = _3114 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3128 = _3119;\n    }\n    if (_3128)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3134 = _3104 > 1;\n        bool _3141;\n        if (_3134)\n        {\n            _3141 = _3114 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3141 = _3134;\n        }\n        if (_3141)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3147 = _3104 > 2;\n        bool _3154;\n        if (_3147)\n        {\n            _3154 = _3114 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3154 = _3147;\n        }\n        if (_3154)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3160 = _3104 > 3;\n        bool _3167;\n        if (_3160)\n        {\n            _3167 = _3114 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3167 = _3160;\n        }\n        if (_3167)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6617 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6617 = -_6617;\n    }\n    vec3 _6240 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6617, fa_world_tangent, fa_uv, fa_vertex_color, _6240, gl_FrontFacing);\n    Surface _6248 = fa_standard_surface(param_1);\n    vec3 _6656 = _6248.albedo;\n    float _6657 = _6248.alpha;\n    vec3 _6658 = _6248.normal;\n    float _6659 = _6248.metallic;\n    float _6660 = _6248.roughness;\n    float _6661 = _6248.occlusion;\n    vec3 _6662 = _6248.emission;\n    float _6663 = _6248.clearcoat;\n    float _6664 = _6248.clearcoat_roughness;\n    vec3 _6665 = _6248.sheen_color;\n    float _6666 = _6248.sheen_roughness;\n    float _6667 = _6248.anisotropy;\n    float _6668 = _6248.anisotropy_rotation;\n    float _6669 = _6248.specular;\n    float _6670 = _6248.ior;\n    vec3 _6671 = _6248.specular_color;\n    float _6672 = _6248.transmission;\n    float _6673 = _6248.thickness;\n    vec3 _6674 = _6248.attenuation_color;\n    float _6675 = _6248.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6617, fa_world_tangent, fa_uv, fa_vertex_color, _6240, gl_FrontFacing);\n    Surface param_3 = _6248;\n    surface(param_2, param_3);\n    _6656 = param_3.albedo;\n    _6657 = param_3.alpha;\n    _6658 = param_3.normal;\n    _6659 = param_3.metallic;\n    _6660 = param_3.roughness;\n    _6661 = param_3.occlusion;\n    _6662 = param_3.emission;\n    _6663 = param_3.clearcoat;\n    _6664 = param_3.clearcoat_roughness;\n    _6665 = param_3.sheen_color;\n    _6666 = param_3.sheen_roughness;\n    _6667 = param_3.anisotropy;\n    _6668 = param_3.anisotropy_rotation;\n    _6669 = param_3.specular;\n    _6670 = param_3.ior;\n    _6671 = param_3.specular_color;\n    _6672 = param_3.transmission;\n    _6673 = param_3.thickness;\n    _6674 = param_3.attenuation_color;\n    _6675 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6617;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6656 = param_6;\n    _6658 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6656;\n    }\n    else\n    {\n        vec3 _6287 = _6658;\n        vec3 _6288 = normalize(_6287);\n        _6658 = _6288;\n        vec3 param_8 = _6288;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _6617, fa_world_tangent, fa_uv, fa_vertex_color, _6240, gl_FrontFacing);\n        Surface param_10 = Surface(_6656, _6657, _6658, _6659, _6660, _6661, _6662, _6663, _6664, _6665, _6666, _6667, _6668, _6669, _6670, _6671, _6672, _6673, _6674, _6675);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6307 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6307; ln++)\n        {\n            int param_12 = ln;\n            int _6320 = fa_cl_light(param_12);\n            int param_13 = _6320;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6320;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _6617;\n            LightSample _6336 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _6617, fa_world_tangent, fa_uv, fa_vertex_color, _6240, gl_FrontFacing);\n            Surface param_18 = Surface(_6656, _6657, _6658, _6659, _6660, _6661, _6662, _6663, _6664, _6665, _6666, _6667, _6668, _6669, _6670, _6671, _6672, _6673, _6674, _6675);\n            LightSample param_19 = _6336;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6351 = result;\n    vec3 _6352 = _6351 + _6662;\n    result = _6352;\n    vec3 param_20 = _6352;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6361 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6368;\n    if (!_6361)\n    {\n        _6368 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6368 = _6361;\n    }\n    if (_6368)\n    {\n        vec3 _6377 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6383 = dot(_6377, fa_mesh_fs_params[9].xyz);\n        bool _6387 = fa_mesh_fs_params[9].w > 0.5;\n        float _6388;\n        if (_6387)\n        {\n            _6388 = _6383;\n        }\n        else\n        {\n            _6388 = length(_6377);\n        }\n        float _6400 = _6388 - fa_mesh_fs_params[8].x;\n        if (_6400 > 0.0)\n        {\n            float _6409 = fa_mesh_fs_params[7].w * _6400;\n            float tau = _6409 * _6409;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6425;\n                if (_6387)\n                {\n                    _6425 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6383);\n                }\n                else\n                {\n                    _6425 = fa_mesh_fs_params[0].y;\n                }\n                float _6446 = mix(_6425, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6388, 0.0, 1.0));\n                float _6450 = fa_world_pos.y - _6446;\n                float _6455 = _6446 - fa_mesh_fs_params[8].z;\n                float _6460 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6463 = _6455 <= 0.0;\n                bool _6464 = !_6463;\n                bool _6470;\n                if (_6464)\n                {\n                    _6470 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6470 = _6463;\n                }\n                float _6471;\n                if (_6470)\n                {\n                    _6471 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6471 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6455, 80.0));\n                }\n                bool _6498;\n                if (_6464)\n                {\n                    _6498 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6498 = _6463;\n                }\n                float _6499;\n                if (_6498)\n                {\n                    _6499 = fa_mesh_fs_params[8].y * _6455;\n                }\n                else\n                {\n                    _6499 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6455, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6524 = _6460 <= 0.0;\n                bool _6531;\n                if (!_6524)\n                {\n                    _6531 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6531 = _6524;\n                }\n                float _6532;\n                if (_6531)\n                {\n                    _6532 = fa_mesh_fs_params[8].y * _6460;\n                }\n                else\n                {\n                    _6532 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6460, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6559;\n                if (abs(_6450) < 0.001000000047497451305389404296875)\n                {\n                    _6559 = _6471;\n                }\n                else\n                {\n                    _6559 = (_6532 - _6499) / _6450;\n                }\n                tau += (_6400 * max(_6559, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6657);\n}\n\n",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4188[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1426 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1433;\n    if (!_1426)\n    {\n        _1433 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1433 = _1426;\n    }\n    bool _1441;\n    if (!_1433)\n    {\n        _1441 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1441 = _1433;\n    }\n    bool _1448;\n    if (!_1441)\n    {\n        _1448 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1448 = _1441;\n    }\n    bool _1455;\n    if (!_1448)\n    {\n        _1455 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1455 = _1448;\n    }\n    if (_1455)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1465 = vec4(world_pos, 1.0);\n    float _1471 = dot(fa_mesh_fs_params[16], _1465);\n    if (!(_1471 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1493 = vec2(dot(fa_mesh_fs_params[14], _1465), dot(fa_mesh_fs_params[15], _1465)) / vec2(_1471);\n    int _1497 = int(fa_mesh_fs_params[18].x);\n    int _1501 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1501) + clamp(int(floor(((_1493.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1501 - 1)) * _1497)) + clamp(int(floor(((_1493.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1497 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1577 = fa_cluster_texel(param);\n    return ivec2(int(_1577.x), int(_1577.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5011 = fa_cluster_lookup(param);\n    fa_cl_slot = _5011.x;\n    fa_cl_local = _5011.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5223 = fa_linear_to_srgb(param);\n        c = _5223;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5231 = fa_srgb_to_linear(param_1);\n            c = _5231;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _380;\n    if (i.front_facing)\n    {\n        _380 = i.world_normal;\n    }\n    else\n    {\n        _380 = -i.world_normal;\n    }\n    vec3 _404 = normalize(i.world_tangent.xyz - (_380 * dot(_380, i.world_tangent.xyz)));\n    vec3 _431 = normalize(((_404 * m.x) + ((cross(_380, _404) * i.world_tangent.w) * m.y)) + (_380 * m.z));\n    vec3 _434;\n    if (i.front_facing)\n    {\n        _434 = _431;\n    }\n    else\n    {\n        _434 = -_431;\n    }\n    return _434;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5262 = fa_tex_fix(param_2, param_3);\n    vec4 _7146 = base_t;\n    _7146.x = _5262.x;\n    _7146.y = _5262.y;\n    _7146.z = _5262.z;\n    base_t = _7146;\n    vec4 _5276 = (_7146 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6952 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5308 = fa_tex_fix(param_6, param_7);\n        vec3 _5311 = (_5308 * 2.0) - vec3(1.0);\n        vec2 _5316 = _5311.xy * fa_mesh_fs_params[6].x;\n        vec3 _7154 = _5311;\n        _7154.x = _5316.x;\n        _7154.y = _5316.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7154;\n        _6952 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5344 = fa_tex_fix(param_12, param_13);\n    vec4 _7157 = mrt;\n    _7157.x = _5344.x;\n    _7157.y = _5344.y;\n    _7157.z = _5344.z;\n    mrt = _7157;\n    vec4 _5372 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5372.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5383 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5413 = fa_tex_fix(param_20, param_21);\n    float _6957 = fa_mesh_fs_params[20].x;\n    float _6958 = fa_mesh_fs_params[20].y;\n    float _6961 = fa_mesh_fs_params[20].z;\n    float _6960 = fa_mesh_fs_params[21].w;\n    float _6963 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6957 *= _5383.y;\n            _6958 *= _5383.z;\n            _6960 *= _5372.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _6961 *= mrt.x;\n            _6963 *= mrt.w;\n        }\n    }\n    return Surface(_5276.xyz, _5276.w, _6952, clamp(fa_mesh_fs_params[5].x * _5344.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5344.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5383.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5413), _6957, _6958, fa_mesh_fs_params[21].xyz, _6960, _6961, fa_mesh_fs_params[20].w, _6963, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1657 = rect.zw - rect.xy;\n    vec2 _1661 = _1657 * atlas;\n    vec2 _1665 = ddx * _1661;\n    vec2 _1669 = ddy * _1661;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1657), clamp(0.5 * log2(max(max(dot(_1665, _1665), dot(_1669, _1669)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1702 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1709;\n    if (!_1702)\n    {\n        _1709 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1709 = _1702;\n    }\n    if (_1709)\n    {\n        return;\n    }\n    vec3 _1715 = dFdx(world_pos);\n    vec3 _1718 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1722 = fa_cluster_texel(param);\n    int _1726 = int(_1722.w);\n    if (_1726 < 1)\n    {\n        return;\n    }\n    int _1736 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1736;\n    vec4 _1740 = fa_light_texel(param_1);\n    vec2 _1743 = _1740.yz;\n    int _1747 = int(_1740.w);\n    int param_2 = _1736 + 1;\n    vec4 _1752 = fa_light_texel(param_2);\n    float _1753 = _1752.x;\n    int _1759 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1763 = int(_1722.z);\n    vec3 _2028;\n    for (int k = 0; k < _1726; k++)\n    {\n        int _1776 = _1763 + k;\n        int param_3 = _1747 + (_1776 >> 2);\n        int _1793 = (_1736 + 2) + (int(fa_light_texel(param_3)[_1776 & 3]) * 7);\n        int param_4 = _1793 + 6;\n        vec4 _1798 = fa_light_texel(param_4);\n        if (((int(_1798.w + 0.5) >> _1759) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1793;\n        vec4 _1813 = fa_light_texel(param_5);\n        int param_6 = _1793 + 1;\n        vec4 _1818 = fa_light_texel(param_6);\n        int param_7 = _1793 + 2;\n        vec4 _1823 = fa_light_texel(param_7);\n        vec3 _1826 = _1813.xyz;\n        float _1831 = dot(_1826, world_pos) + _1813.w;\n        vec3 _1833 = _1818.xyz;\n        float _1838 = dot(_1833, world_pos) + _1818.w;\n        vec3 _1840 = _1823.xyz;\n        float _1845 = dot(_1840, world_pos) + _1823.w;\n        bool _1850 = abs(_1831) > 0.5;\n        bool _1858;\n        if (!_1850)\n        {\n            _1858 = abs(_1838) > 0.5;\n        }\n        else\n        {\n            _1858 = _1850;\n        }\n        bool _1866;\n        if (!_1858)\n        {\n            _1866 = abs(_1845) > 0.5;\n        }\n        else\n        {\n            _1866 = _1858;\n        }\n        if (_1866)\n        {\n            continue;\n        }\n        float _1881 = clamp(dot(geo_normal, normalize(_1840)) * _1798.z, 0.0, 1.0);\n        if (_1881 <= 0.0)\n        {\n            continue;\n        }\n        float _1901 = (clamp((0.5 - abs(_1845)) * 10.0, 0.0, 1.0) * _1881) * _1798.x;\n        vec2 _1909 = vec2(_1831 + 0.5, 0.5 - _1838);\n        vec2 _1919 = vec2(dot(_1826, _1715), dot(_1833, _1715));\n        vec2 _1929 = vec2(dot(_1826, _1718), dot(_1833, _1718));\n        int param_8 = _1793 + 5;\n        vec4 _1934 = fa_light_texel(param_8);\n        int param_9 = _1793 + 3;\n        vec4 _1939 = fa_light_texel(param_9);\n        int param_10 = _1793 + 4;\n        vec4 _1944 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1934.xyz;\n        bool _1954 = _1939.z > _1939.x;\n        if (_1954)\n        {\n            vec4 param_11 = _1939;\n            vec2 param_12 = _1909;\n            vec2 param_13 = _1743;\n            vec2 param_14 = _1919;\n            vec2 param_15 = _1929;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1753 > 0.5) && (_1753 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1980 = fa_dc_to_linear(param_16);\n                vec4 _7040 = tx;\n                _7040.x = _1980.x;\n                _7040.y = _1980.y;\n                _7040.z = _1980.z;\n                tx = _7040;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1901 * tex_a) * _1934.w, 0.0, 1.0)));\n        if (_1944.z > _1944.x)\n        {\n            vec4 param_17 = _1944;\n            vec2 param_18 = _1909;\n            vec2 param_19 = _1743;\n            vec2 param_20 = _1919;\n            vec2 param_21 = _1929;\n            vec4 _2024 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1753 > 1.5)\n            {\n                vec3 param_22 = _2024.xyz;\n                vec3 _2034 = fa_dc_to_srgb(param_22);\n                _2028 = _2034;\n            }\n            else\n            {\n                _2028 = _2024.xyz;\n            }\n            vec3 _2043 = (_2028 * 2.0) - vec3(1.0);\n            vec2 _2048 = _2043.xy * _1798.y;\n            vec3 _2070 = (normalize(_1826) * _2048.x) + (normalize(_1833) * _2048.y);\n            vec3 _2073 = normalize(normal);\n            normal = normalize(mix(_2073, normalize((_2073 * max(_2043.z, 0.0500000007450580596923828125)) + (_2070 - (_2073 * dot(_2073, _2070)))), vec3(clamp(_1901 * (_1954 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3281 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3281;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3894 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3899 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3894 > 0.0005000000237487256526947021484375)\n    {\n        if (_3899)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3894;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3894;\n        }\n    }\n    bool _3950 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3950)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _3981 = fa_mesh_fs_params[47].w > 0.0;\n    if (_3981)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3899 || _3950) || _3981)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3301 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3304 = _3301.x;\n    float _3306 = _3301.z;\n    vec2 e = vec2(_3304, _3306);\n    if (_3301.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3306)) * ((_3304 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3304)) * ((_3306 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _5525 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _5530 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _5535 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _5540 = fa_light_texel(param_3);\n    bool _5543 = _5540.z < 0.5;\n    bool _5551;\n    if (!_5543)\n    {\n        _5551 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _5551 = _5543;\n    }\n    if (_5551)\n    {\n        return vec3(0.0);\n    }\n    float _5558 = max(_5525.w, 9.9999997473787516355514526367188e-05);\n    vec3 _5561 = _5530.xyz;\n    vec3 _5565 = _5525.xyz;\n    vec3 _5569 = (fa_world_pos - _5565) / vec3(_5558);\n    vec3 _5578 = min(_5569 + vec3(0.5), (_5561 - vec3(0.5)) - _5569);\n    float _5587 = min(_5578.x, min(_5578.y, _5578.z));\n    if (!(_5587 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5602 = _5561 - vec3(1.0);\n    vec3 _5603 = clamp(_5569, vec3(0.0), _5602);\n    vec3 _5611 = min(floor(_5603), max(_5561 - vec3(2.0), vec3(0.0)));\n    vec3 _5615 = _5603 - _5611;\n    vec3 _5626 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _5558));\n    int _5631 = int(_5535.y + 0.5);\n    float _5636 = 0.3257350027561187744140625 * n.y;\n    float _5640 = 0.3257350027561187744140625 * n.z;\n    float _5644 = 0.3257350027561187744140625 * n.x;\n    float _5651 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _5658 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _5667 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _5674 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _5687 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _5694 = 8 + int(_5540.w);\n    float _5721;\n    float _5734;\n    float _5748;\n    for (int k = 0; k < _5694; k++)\n    {\n        float _5707 = float(k & 1);\n        float _5711 = float((k >> 1) & 1);\n        float _5715 = float((k >> 2) & 1);\n        if (_5707 > 0.5)\n        {\n            _5721 = _5615.x;\n        }\n        else\n        {\n            _5721 = 1.0 - _5615.x;\n        }\n        if (_5711 > 0.5)\n        {\n            _5734 = _5615.y;\n        }\n        else\n        {\n            _5734 = 1.0 - _5615.y;\n        }\n        if (_5715 > 0.5)\n        {\n            _5748 = _5615.z;\n        }\n        else\n        {\n            _5748 = 1.0 - _5615.z;\n        }\n        float _5758 = (_5721 * _5734) * _5748;\n        if (!(_5758 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5771 = min(_5611 + vec3(_5707, _5711, _5715), _5602);\n        int _5791 = int(((_5535.x + _5771.x) + (_5530.x * (_5771.y + (_5530.y * _5771.z)))) + 0.5);\n        vec2 _5806 = vec2(float(_5791 % _5631) * 10.0, 1024.0 + (float(_5791 / _5631) * 11.0));\n        vec2 param_4 = _5806 + vec2(9.5, 10.5);\n        vec4 _5814 = fa_gi_fetch(param_4);\n        bool _5817 = _5814.y < 0.5;\n        bool _5826;\n        if (!_5817)\n        {\n            _5826 = _5814.x > _5540.y;\n        }\n        else\n        {\n            _5826 = _5817;\n        }\n        if (_5826)\n        {\n            continue;\n        }\n        vec3 _5838 = _5626 - (_5565 + (_5771 * _5558));\n        float _5841 = length(_5838);\n        vec3 _5847 = _5838 / vec3(max(_5841, 9.9999997473787516355514526367188e-05));\n        float _5857 = max(9.9999997473787516355514526367188e-05, (dot(-_5847, n) + 1.0) * 0.5);\n        float w = _5758 * (_5857 * _5857);\n        vec3 param_5 = _5847;\n        vec2 param_6 = (_5806 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5876 = fa_gi_fetch(param_6);\n        float _5883 = _5841 / max(_5535.z, 9.9999997473787516355514526367188e-05);\n        float _5886 = _5876.x;\n        if (_5883 > _5886)\n        {\n            float _5899 = max(_5876.y - (_5886 * _5886), 0.0);\n            float _5904 = _5883 - _5886;\n            float _5913 = _5899 / max(_5899 + (_5904 * _5904), 9.9999999600419720025001879548654e-13);\n            w *= ((_5913 * _5913) * _5913);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5806 + vec2(0.5, 10.5);\n        vec2 param_8 = _5806 + vec2(1.5, 10.5);\n        vec2 param_9 = _5806 + vec2(2.5, 10.5);\n        vec2 param_10 = _5806 + vec2(3.5, 10.5);\n        vec2 param_11 = _5806 + vec2(4.5, 10.5);\n        vec2 param_12 = _5806 + vec2(5.5, 10.5);\n        vec2 param_13 = _5806 + vec2(6.5, 10.5);\n        vec2 param_14 = _5806 + vec2(7.5, 10.5);\n        vec2 param_15 = _5806 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _5636)) + (fa_gi_fetch(param_9).xyz * _5640)) + (fa_gi_fetch(param_10).xyz * _5644)) + (fa_gi_fetch(param_11).xyz * _5651)) + (fa_gi_fetch(param_12).xyz * _5658)) + (fa_gi_fetch(param_13).xyz * _5667)) + (fa_gi_fetch(param_14).xyz * _5674)) + (fa_gi_fetch(param_15).xyz * _5687)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_5587 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6039;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6039 = _5540.x;\n    }\n    else\n    {\n        _6039 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_5535.w * _6039);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6063 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6068 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6073 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6073) && (k < 8); k++)\n    {\n        int param = _6068 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6063;\n        vec3 _6098 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6103 = param_3 * left;\n        acc += (_6098 * _6103);\n        left -= _6103;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6132 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6132;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4113 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4121 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4124 = int(_4113);\n    int _4127 = int(_4121);\n    float _4137 = _4121 - float(_4127);\n    int _4192 = (_4124 * 9) + _4127;\n    int _4212 = ((_4124 + 1) * 9) + _4127;\n    return mix(mix(_4188[_4192], _4188[_4192 + 1], _4137), mix(_4188[_4212], _4188[_4212 + 1], _4137), _4113 - float(_4124));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6811 = false;\n    float _6812 = 1.0;\n    float _6813 = 1.0;\n    float _6814 = 1.0;\n    float _6815 = 0.0;\n    float _6816 = 0.0;\n    float _6817 = 0.0;\n    float _6818 = 0.0;\n    float _6820 = 1.0;\n    bool _6821 = false;\n    vec3 _6822 = vec3(0.0);\n    float _6823 = 1.0;\n    float _6824 = 1.0;\n    float _6825 = 1.0;\n    float _6826 = 0.0;\n    float _6827 = 0.0;\n    vec3 _6828 = vec3(1.0, 0.0, 0.0);\n    vec3 _6829 = vec3(0.0, 0.0, 1.0);\n    float _6830 = 1.0;\n    float _6831 = 1.0;\n    float _4263 = clamp(s.specular, 0.0, 1.0);\n    float _4267 = clamp(s.ior, 1.0, 3.0);\n    bool _4272 = (_4263 != 1.0) || (_4267 != 1.5);\n    bool _4281;\n    if (!_4272)\n    {\n        _4281 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4281 = _4272;\n    }\n    if (_4281)\n    {\n        float _4289 = (_4267 - 1.0) / (_4267 + 1.0);\n        f0 = mix(min(vec3(_4289 * _4289) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4263, s.albedo, vec3(metallic));\n        _6812 = mix(_4263, 1.0, metallic);\n        _6811 = true;\n    }\n    float _4316 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4316 > 0.0)\n    {\n        float _4324 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6815 = _4316;\n        _6816 = _4324;\n        float _4331 = _4324 * _4324;\n        _6817 = _4331;\n        _6818 = _4331 * _4331;\n        float _4343 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6820 = _4343;\n        _6813 = 1.0 - (_4316 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4343, 0.0, 1.0), 5.0))));\n        _6811 = true;\n    }\n    vec3 _4362 = max(s.sheen_color, vec3(0.0));\n    float _4371 = max(_4362.x, max(_4362.y, _4362.z));\n    if (_4371 > 0.0)\n    {\n        float _4379 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6821 = true;\n        _6822 = _4362;\n        _6823 = _4379;\n        _6824 = _4379 * _4379;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4379;\n        float _4396 = fa_sheen_albedo(param, param_1);\n        _6826 = _4396;\n        _6825 = 1.0 - min(_4371 * _4396, 1.0);\n        _6811 = true;\n    }\n    _6814 = _6813 * _6825;\n    float _4415 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4415 != 0.0)\n    {\n        vec3 _4430 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4430;\n        if (dot(_4430, _4430) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4442 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4442.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4442.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4442.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4446 = t;\n        vec3 _4447 = normalize(_4446);\n        t = _4447;\n        vec3 _4472 = normalize((_4447 * cos(s.anisotropy_rotation)) + ((cross(n, _4447) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6828 = _4472;\n        _6829 = cross(n, _4472);\n        float _4482 = roughness * roughness;\n        float _4488 = mix(_4482, 1.0, _4415 * _4415);\n        bool _4490 = _4415 > 0.0;\n        _6830 = _4490 ? _4488 : _4482;\n        _6831 = _4490 ? _4482 : _4488;\n        _6827 = _4415;\n        _6811 = true;\n    }\n    return FaLayers(_6811, _6812, _6813, _6814, _6815, _6816, _6817, _6818, i.world_normal, _6820, _6821, _6822, _6823, _6824, _6825, _6826, _6827, _6828, _6829, _6830, _6831);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4045 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4048 = _4045.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4048 * _4048, exp2((-9.27999973297119140625) * ndv)) * _4048) + _4045.y)) + _4045.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3353;\n    if (lv == 0)\n    {\n        _3353 = 0.0;\n    }\n    else\n    {\n        _3353 = res + 2.0;\n    }\n    float _3363;\n    if (lv == 0)\n    {\n        _3363 = 0.0;\n    }\n    else\n    {\n        _3363 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3353, _3363)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3409;\n    if (res > 64.5)\n    {\n        _3409 = 5.0;\n    }\n    else\n    {\n        _3409 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3424 = clamp(rough, 0.0, 1.0) * (_3409 - 1.0);\n    int _3431 = int(min(floor(_3424), _3409 - 2.0));\n    float _3436 = _3424 - float(_3431);\n    vec3 param = d;\n    vec2 _3440 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3431;\n    vec2 param_4 = _3440;\n    vec3 _3450 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3436 < 0.00200000009499490261077880859375)\n    {\n        return _3450;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3431 + 1;\n    vec2 param_8 = _3440;\n    return mix(_3450, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3436));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3523 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3530 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3537 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3543 = dot(bx.xyz, d);\n    float _3547 = dot(by.xyz, d);\n    float _3551 = dot(bz.xyz, d);\n    float _3557;\n    if (_3543 > 9.9999999747524270787835121154785e-07)\n    {\n        _3557 = (1.0 - _3523) / _3543;\n    }\n    else\n    {\n        float _3571;\n        if (_3543 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3571 = ((-1.0) - _3523) / _3543;\n        }\n        else\n        {\n            _3571 = 1000000015047466219876688855040.0;\n        }\n        _3557 = _3571;\n    }\n    float tx = _3557;\n    float _3588;\n    if (_3547 > 9.9999999747524270787835121154785e-07)\n    {\n        _3588 = (1.0 - _3530) / _3547;\n    }\n    else\n    {\n        float _3601;\n        if (_3547 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3601 = ((-1.0) - _3530) / _3547;\n        }\n        else\n        {\n            _3601 = 1000000015047466219876688855040.0;\n        }\n        _3588 = _3601;\n    }\n    float ty = _3588;\n    float _3617;\n    if (_3551 > 9.9999999747524270787835121154785e-07)\n    {\n        _3617 = (1.0 - _3537) / _3551;\n    }\n    else\n    {\n        float _3630;\n        if (_3551 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3630 = ((-1.0) - _3537) / _3551;\n        }\n        else\n        {\n            _3630 = 1000000015047466219876688855040.0;\n        }\n        _3617 = _3630;\n    }\n    float _3642 = tx;\n    float _3645 = (_3642 > 0.0) ? _3642 : 1000000015047466219876688855040.0;\n    tx = _3645;\n    float _3646 = ty;\n    float _3649 = (_3646 > 0.0) ? _3646 : 1000000015047466219876688855040.0;\n    ty = _3649;\n    float _3659 = min(_3645, min(_3649, (_3617 > 0.0) ? _3617 : 1000000015047466219876688855040.0));\n    if (_3659 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3675 = (fa_world_pos + (d * _3659)) - posw.xyz;\n    vec3 _3680;\n    if (dot(_3675, _3675) > 1.0000000133514319600180897396058e-10)\n    {\n        _3680 = normalize(_3675);\n    }\n    else\n    {\n        _3680 = d;\n    }\n    return _3680;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3726 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3726 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3754 = rough * rough;\n            float _3785 = 0.60000002384185791015625 * _3754;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3754)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3785, 0.0500000007450580596923828125 + _3785, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3754 * 0.60000002384185791015625));\n        }\n        outc = base * _3726;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3844 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3844 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3876 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3876 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4523;\n        if (L.aniso >= 0.0)\n        {\n            _4523 = L.b;\n        }\n        else\n        {\n            _4523 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4523, v), _4523), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4559 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4559.x) + (vec3(L.f90) * _4559.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4617 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4617.x) + _4617.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4087 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4087.x) + vec3(_4087.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4646 = clamp(s.metallic, 0.0, 1.0);\n    float _4650 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4657 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4646));\n    vec3 f0 = _4657;\n    vec3 _4661 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4661;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4646;\n    float param_5 = _4650;\n    vec3 param_6 = _4657;\n    FaLayers _4678 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4678.on)\n    {\n        FaLayers param_7 = _4678;\n        vec3 param_8 = _4661;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4650;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4661;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4650;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4981;\n    if (fa_lm.z > 0.5)\n    {\n        _4981 = 0.0;\n    }\n    else\n    {\n        _4981 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _4992 = _4981 < 1.0;\n    bool _4998;\n    if (_4992)\n    {\n        int param = li;\n        _4998 = fa_light_baked(param);\n    }\n    else\n    {\n        _4998 = _4992;\n    }\n    return _4998 ? _4981 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _676 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _689 = (c - (ru * hx)) - p;\n        vec3 _695 = ru * (2.0 * hx);\n        float _701 = max(dot(_695, _695), 9.9999999392252902907785028219223e-09);\n        float _705 = dot(_689, _695);\n        float t = clamp((-_705) / _701, 0.0, 1.0);\n        if (_676)\n        {\n            float _720 = dot(r, _695);\n            float _726 = _701 - (_720 * _720);\n            if (abs(_726) > (9.9999997473787516355514526367188e-06 * _701))\n            {\n                t = clamp(((dot(r, _689) * _720) - _705) / _726, 0.0, 1.0);\n            }\n        }\n        return (p + _689) + (_695 * t);\n    }\n    vec3 q = p;\n    float _758 = dot(r, axis);\n    bool _766;\n    if (_676)\n    {\n        _766 = abs(_758) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _766 = _676;\n    }\n    if (_766)\n    {\n        float _776 = dot(c - p, axis) / _758;\n        if (_776 > 0.0)\n        {\n            q = p + (r * _776);\n        }\n    }\n    vec3 _789 = q - c;\n    vec2 xy = vec2(dot(_789, ru), dot(_789, uu));\n    if (shape > 0.5)\n    {\n        float _804 = length(xy);\n        if (_804 > hx)\n        {\n            xy *= (hx / _804);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _596 = dot(d, right);\n    float _600 = dot(d, up);\n    float _611;\n    if (((_596 * _596) + (_600 * _600)) > 1.0000000133514319600180897396058e-10)\n    {\n        _611 = atan(_600, _596) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _611 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_611 - floor(_611)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _446 = abs(d);\n    float _448 = _446.x;\n    float _450 = _446.y;\n    bool _451 = _448 >= _450;\n    bool _459;\n    if (_451)\n    {\n        _459 = _448 >= _446.z;\n    }\n    else\n    {\n        _459 = _451;\n    }\n    int _460;\n    if (_459)\n    {\n        _460 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _475;\n        if (_450 >= _446.z)\n        {\n            _475 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _475 = (d.z > 0.0) ? 4 : 5;\n        }\n        _460 = _475;\n    }\n    return _460;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _842 = fa_light_base(param);\n    bool _846 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _842;\n    vec4 _850 = fa_light_texel(param_1);\n    int param_2 = _842 + 1;\n    vec4 _855 = fa_light_texel(param_2);\n    float _858 = _855.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _870 = _846 && (_858 > 2.5);\n    fa_light_is_area = _870;\n    bool _872 = _858 < 0.5;\n    vec3 l;\n    if (_872)\n    {\n        l = normalize(_850.xyz);\n        if (_846)\n        {\n            int param_3 = _842 + 6;\n            vec4 _886 = fa_light_texel(param_3);\n            if (_886.z > 0.5)\n            {\n                int param_4 = _842 + 4;\n                vec4 _896 = fa_light_texel(param_4);\n                int param_5 = _842 + 5;\n                vec4 _901 = fa_light_texel(param_5);\n                vec2 param_6 = _886.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _896.xyz) * _896.w, (-dot(world_pos, _901.xyz)) * _901.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _931 = _850.xyz;\n        vec3 _933 = _931 - world_pos;\n        vec3 to_light = _933;\n        float _936 = length(_933);\n        float reach = _936;\n        bool front = true;\n        if (_870)\n        {\n            int param_8 = _842 + 7;\n            reach = max(_936 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _842 + 4;\n            vec4 _960 = fa_light_texel(param_9);\n            int param_10 = _842 + 5;\n            vec4 _965 = fa_light_texel(param_10);\n            int param_11 = _842 + 6;\n            vec4 _970 = fa_light_texel(param_11);\n            float _971 = _970.w;\n            int param_12 = _842 + 2;\n            vec3 _978 = normalize(fa_light_texel(param_12).xyz);\n            bool _980 = _971 > 1.5;\n            bool _988;\n            if (!_980)\n            {\n                _988 = dot(_978, to_light) < 0.0;\n            }\n            else\n            {\n                _988 = _980;\n            }\n            front = _988;\n            vec3 r = vec3(0.0);\n            vec3 _997 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1001 = dot(n, n) > 0.5;\n            bool _1009;\n            if (_1001)\n            {\n                _1009 = dot(_997, _997) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1009 = _1001;\n            }\n            if (_1009)\n            {\n                r = reflect(-normalize(_997), normalize(n));\n            }\n            vec3 param_13 = _931;\n            vec3 param_14 = _978;\n            vec3 param_15 = _960.xyz;\n            vec3 param_16 = _965.xyz;\n            float param_17 = _960.w;\n            float param_18 = _965.w;\n            float param_19 = _971;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1045 = length(to_light);\n        dist = _1045;\n        l = to_light / vec3(max(_1045, 9.9999997473787516355514526367188e-05));\n        float _1059 = reach / max(_850.w, 0.001000000047497451305389404296875);\n        float _1065 = clamp(1.0 - (_1059 * _1059), 0.0, 1.0);\n        float _1067;\n        if (front)\n        {\n            _1067 = _1065 * _1065;\n        }\n        else\n        {\n            _1067 = 0.0;\n        }\n        atten = _1067;\n        bool _1078 = _858 < 2.5;\n        if ((_858 > 1.5) && _1078)\n        {\n            int param_22 = _842 + 2;\n            vec4 _1086 = fa_light_texel(param_22);\n            float _1096 = _1086.w;\n            int param_23 = _842 + 3;\n            vec4 _1101 = fa_light_texel(param_23);\n            float _1102 = _1101.x;\n            float cos_inner = _1102;\n            if (_1102 > 1.5)\n            {\n                cos_inner = mix(_1096, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1096, cos_inner, dot(-l, normalize(_1086.xyz)));\n        }\n        if (_846 && (_858 < 1.5))\n        {\n            int param_24 = _842 + 6;\n            vec4 _1126 = fa_light_texel(param_24);\n            if (_1126.z > 0.5)\n            {\n                vec3 _1134 = -to_light;\n                int param_25 = _842 + 4;\n                int param_26 = _842 + 5;\n                vec3 _1148 = fa_light_texel(param_25).xyz;\n                vec3 _1152 = fa_light_texel(param_26).xyz;\n                vec3 _1161 = vec3(dot(_1134, _1148), dot(_1134, _1152), dot(_1134, cross(_1148, _1152)));\n                vec3 param_27 = _1161;\n                int _1165 = fa_cube_face(param_27);\n                int param_28 = _1165;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1192 = vec2(dot(_1161, cross(param_29, param_30)), dot(_1161, param_30)) / vec2(max(dot(_1161, param_29), 9.9999997473787516355514526367188e-05));\n                int _1196 = _1165 / 3;\n                vec2 param_31 = _1126.xy + (vec2(float(_1165 - (_1196 * 3)), float(_1196)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1192.x), 0.5 - (0.5 * _1192.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _842 + 7;\n            vec4 _1226 = fa_light_texel(param_33);\n            if (_1226.z > 0.5)\n            {\n                int param_34 = _842 + 2;\n                int param_35 = _842 + 4;\n                int param_36 = _842 + 5;\n                vec2 param_37 = _1226.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_846 && _1078)\n            {\n                int param_42 = _842 + 6;\n                vec4 _1273 = fa_light_texel(param_42);\n                int param_43 = _842 + 7;\n                vec4 _1278 = fa_light_texel(param_43);\n                bool _1281 = _1273.z > 0.5;\n                bool _1288;\n                if (!_1281)\n                {\n                    _1288 = _1278.z > 0.5;\n                }\n                else\n                {\n                    _1288 = _1281;\n                }\n                if (_1288)\n                {\n                    int param_44 = _842 + 2;\n                    vec4 _1295 = fa_light_texel(param_44);\n                    vec3 _1299 = normalize(_1295.xyz);\n                    int param_45 = _842 + 4;\n                    vec4 _1304 = fa_light_texel(param_45);\n                    int param_46 = _842 + 5;\n                    vec4 _1309 = fa_light_texel(param_46);\n                    if (_1281)\n                    {\n                        vec3 _1317 = -to_light;\n                        float _1324 = _1295.w;\n                        float _1340 = 0.5 / max(dot(_1317, _1299) * (sqrt(max(1.0 - (_1324 * _1324), 0.0)) / max(_1324, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1273.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1317, _1304.xyz) * _1340), 0.5 - (dot(_1317, _1309.xyz) * _1340));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1278.z > 0.5)\n                    {\n                        vec2 param_49 = _1278.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1299;\n                        vec3 param_52 = _1304.xyz;\n                        vec3 param_53 = _1309.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6799 = _855.xyz * atten;\n    if (_846)\n    {\n        _6799 *= fa_light_tint;\n    }\n    int _1408;\n    if (_872)\n    {\n        _1408 = 0;\n    }\n    else\n    {\n        _1408 = ((_858 > 1.5) && (_858 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6799, atten, 1.0, dist, _1408);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2197 = fa_shadow_depth(param, param_1);\n    float _2201;\n    if (conv.x < 0.5)\n    {\n        _2201 = _2197;\n    }\n    else\n    {\n        _2201 = (conv.y * conv.z) / (conv.z - (_2197 * (conv.z - conv.y)));\n    }\n    return _2201;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2247 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2253 = vec2(cos(_2247), sin(_2247));\n    vec2 dir = _2253;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2262;\n        if (k < 0.0)\n        {\n            _2262 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2262 = k;\n        }\n        float _2281 = clamp((_2262 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2300 = sqrt((float(i) + 0.5) * 0.0625) * _2281;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2300));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2314 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2314 < (zr - (_2300 * plane)))\n            {\n                sum += _2314;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2342 = sum / cnt;\n        float _2352;\n        if (k < 0.0)\n        {\n            _2352 = (-k) / max(_2342, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2352 = k;\n        }\n        radius = clamp(((max(zr - _2342, 0.0) * unit) * _2352) / texel_m, 1.5, 16.0);\n        dir = _2253;\n    }\n    float lit = 0.0;\n    int _2378 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2378; i_1++)\n    {\n        float _2397 = sqrt((float(i_1) + 0.5) / float(_2378)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2397));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2397 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2378);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2602 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2609;\n    if (!_2602)\n    {\n        _2609 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2609 = _2602;\n    }\n    if (_2609)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2622 = fa_light_texel(param);\n    float _2623 = _2622.x;\n    if (_2623 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2632 = int(_2623 + 0.5);\n    int param_1 = _2632;\n    vec4 _2636 = fa_light_texel(param_1);\n    int param_2 = _2632 + 1;\n    vec4 _2641 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2644 = _2636.y;\n    if (_2644 > 0.0)\n    {\n        float _2661 = 1.0 - smoothstep(0.75 * _2644, _2644, length(world - fa_shadows[27].xyz));\n        fade = _2661;\n        if (_2661 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2636.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2685 = (_2632 + 2) + (face * 6);\n    int param_4 = _2685;\n    int param_5 = _2685 + 1;\n    int param_6 = _2685 + 3;\n    vec4 _2699 = fa_light_texel(param_6);\n    int param_7 = _2685 + 4;\n    vec4 _2704 = fa_light_texel(param_7);\n    int param_8 = _2685 + 5;\n    vec4 _2709 = fa_light_texel(param_8);\n    float _2721 = _2709.x * max(dot(_2699, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2726 = clamp(dot(n, l), 0.0, 1.0);\n    float _2749 = clamp(dot(n, _2699.xyz), -1.0, 1.0);\n    float _2768 = min(sqrt(1.0 - (_2749 * _2749)) / max(abs(dot(n, world - lpos)) / max(dot(_2699, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2771 = _2641.y;\n    float _2773;\n    if (_2771 > 0.0)\n    {\n        _2773 = _2771;\n    }\n    else\n    {\n        _2773 = 1.5 * _2721;\n    }\n    vec4 _2793 = vec4(world + (n * (_2773 * sqrt(1.0 - (_2726 * _2726)))), 1.0);\n    float _2797 = dot(_2699, _2793);\n    float _2800 = _2709.y;\n    if (_2797 < _2800)\n    {\n        return 1.0;\n    }\n    vec2 _2815 = vec2(dot(fa_light_texel(param_4), _2793), dot(fa_light_texel(param_5), _2793)) / vec2(_2797);\n    float _2817 = _2815.x;\n    bool _2820 = _2817 < _2704.x;\n    bool _2829;\n    if (!_2820)\n    {\n        _2829 = _2817 > _2704.z;\n    }\n    else\n    {\n        _2829 = _2820;\n    }\n    bool _2838;\n    if (!_2829)\n    {\n        _2838 = _2815.y < _2704.y;\n    }\n    else\n    {\n        _2838 = _2829;\n    }\n    bool _2847;\n    if (!_2838)\n    {\n        _2847 = _2815.y > _2704.w;\n    }\n    else\n    {\n        _2847 = _2838;\n    }\n    if (_2847)\n    {\n        return 1.0;\n    }\n    float _2853 = _2641.x;\n    float _2855;\n    if (_2853 > 0.0)\n    {\n        _2855 = _2853;\n    }\n    else\n    {\n        _2855 = 1.5 * _2721;\n    }\n    vec2 param_9 = _2815;\n    vec4 param_10 = _2704;\n    float param_11 = _2797 - (_2855 * (1.0 + (0.5 * _2768)));\n    float param_12 = _2721;\n    float param_13 = 1.0;\n    float param_14 = _2709.z * 0.25;\n    float param_15 = (_2721 * min(_2768, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2800, _2709.z);\n    int param_17 = int(_2636.z + 0.5);\n    float param_18 = _2636.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2140;\n    if (i == 0)\n    {\n        _2140 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2156;\n        if (i == 1)\n        {\n            _2156 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2164;\n            if (i == 2)\n            {\n                _2164 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2164 = fa_shadows[24].w;\n            }\n            _2156 = _2164;\n        }\n        _2140 = _2156;\n    }\n    return _2140;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2443 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2448 = clamp(dot(n, l), 0.0, 1.0);\n    float _2454 = sqrt(1.0 - (_2448 * _2448));\n    float _2462 = min(_2454 / max(_2448, 0.20000000298023223876953125), 4.0);\n    float _2467;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2467 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2467 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2492 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2467 * _2454)), 1.0);\n    float _2499 = _2492.x;\n    bool _2502 = _2499 < fa_shadows[ci * 1 + 16].x;\n    bool _2511;\n    if (!_2502)\n    {\n        _2511 = _2499 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2511 = _2502;\n    }\n    bool _2520;\n    if (!_2511)\n    {\n        _2520 = _2492.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2520 = _2511;\n    }\n    bool _2529;\n    if (!_2520)\n    {\n        _2529 = _2492.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2529 = _2520;\n    }\n    bool _2536;\n    if (!_2529)\n    {\n        _2536 = _2492.z > 1.0;\n    }\n    else\n    {\n        _2536 = _2529;\n    }\n    if (_2536)\n    {\n        return -1.0;\n    }\n    float _2544;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2544 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2544 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2492.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2492.z - ((_2544 * (1.0 + (0.5 * _2462))) / _2443);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2443;\n    float param_5 = _2443 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2462, 3.0)) * 0.5) / _2443;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2922 = int(fa_shadows[25].x + 0.5);\n    if (_2922 < 1)\n    {\n        return 1.0;\n    }\n    float _2937 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2922 - 1;\n    if (_2937 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2949 = _2922 > 1;\n    bool _2956;\n    if (_2949)\n    {\n        _2956 = _2937 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2956 = _2949;\n    }\n    if (_2956)\n    {\n        ci = 1;\n    }\n    bool _2960 = _2922 > 2;\n    bool _2967;\n    if (_2960)\n    {\n        _2967 = _2937 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2967 = _2960;\n    }\n    if (_2967)\n    {\n        ci = 2;\n    }\n    bool _2971 = _2922 > 3;\n    bool _2978;\n    if (_2971)\n    {\n        _2978 = _2937 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2978 = _2971;\n    }\n    if (_2978)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2922)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3004 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3004;\n        if (_3004 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3029;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3029 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3029 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3048 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3029, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3059 = clamp((_2937 - (fa_shadow_split_at(param_7) - _3048)) / _3048, 0.0, 1.0);\n        if (_3059 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2922)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3080 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3080;\n                if (_3080 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3059);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4717 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4724;\n    if (!_4717)\n    {\n        _4724 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4724 = _4717;\n    }\n    if (_4724)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4737 = fa_light_texel(param);\n    float _4738 = _4737.y;\n    float len = _4738;\n    if (_4738 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4750 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4760 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4750);\n    if (_4760 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4766 = len;\n    float _4769 = min(_4766, 0.89999997615814208984375 * dist);\n    len = _4769;\n    float _4774 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4750);\n    float _4779 = _4774 + (0.5 * _4769);\n    vec3 _4785 = world + (gn * _4774);\n    float _4787 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4851;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4802 = (float(k) + _4787) * 0.083333335816860198974609375;\n        vec3 _4810 = _4785 + (l * (_4802 * len));\n        vec4 _4816 = vec4(_4810, 1.0);\n        float _4822 = dot(fa_mesh_fs_params[28], _4816);\n        if (_4822 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4842 = vec2(dot(fa_mesh_fs_params[26], _4816), dot(fa_mesh_fs_params[27], _4816)) / vec2(_4822);\n        float _4846 = _4842.x * 0.5;\n        float _4847 = _4846 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4851 = (_4842.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4851 = 0.5 - (_4842.y * 0.5);\n        }\n        bool _4867 = _4847 < 0.0;\n        bool _4874;\n        if (!_4867)\n        {\n            _4874 = _4847 >= 1.0;\n        }\n        else\n        {\n            _4874 = _4867;\n        }\n        bool _4881;\n        if (!_4874)\n        {\n            _4881 = _4851 < 0.0;\n        }\n        else\n        {\n            _4881 = _4874;\n        }\n        bool _4888;\n        if (!_4881)\n        {\n            _4888 = _4851 >= 1.0;\n        }\n        else\n        {\n            _4888 = _4881;\n        }\n        if (_4888)\n        {\n            break;\n        }\n        vec4 _4915 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4847, _4851) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4915.w < 0.5)\n        {\n            continue;\n        }\n        float _4934 = (dot(fa_mesh_fs_params[29].xyz, _4810) + fa_mesh_fs_params[29].w) - _4915.x;\n        if ((_4934 > _4774) && (_4934 < _4779))\n        {\n            occ = max(occ, (1.0 - (_4802 * _4802)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4847, 0.5 - _4846), min(_4851, 1.0 - _4851))));\n        }\n    }\n    return 1.0 - (occ * _4760);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5037 = fa_baked_keep(param);\n    if (_5037 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5063 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6932 = _5063.color;\n    float _6933 = _5063.attenuation;\n    float _6934 = _5063.shadow;\n    bool _5066 = _5063.type == 0;\n    if (_5066 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5063.direction;\n        float _5077 = fa_shadow_factor(param_5, param_6);\n        _6934 = _5077;\n        _6932 *= _5077;\n    }\n    else\n    {\n        bool _5088 = _5063.type != 0;\n        bool _5094;\n        if (_5088)\n        {\n            _5094 = _6933 > 0.0;\n        }\n        else\n        {\n            _5094 = _5088;\n        }\n        if (_5094)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5063.direction;\n            float _5113 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6934 = _5113;\n            _6932 *= _5113;\n        }\n    }\n    bool _5123 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5129;\n    if (_5123)\n    {\n        _5129 = _6933 > 0.0;\n    }\n    else\n    {\n        _5129 = _5123;\n    }\n    if (_5129)\n    {\n        float _5136;\n        if (_5066)\n        {\n            _5136 = 1000000000.0;\n        }\n        else\n        {\n            _5136 = _5063._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5063.direction;\n        float param_18 = _5136;\n        float _5154 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6934 *= _5154;\n        _6932 *= _5154;\n    }\n    float _5167 = _6933;\n    float _5168 = _5167 * _5037;\n    _6933 = _5168;\n    vec3 _5172 = _6932;\n    vec3 _5173 = _5172 * _5037;\n    _6932 = _5173;\n    return LightSample(_5063.direction, _5173, _5168, _6934, _5063._distance, _5063.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3104 = int(fa_shadows[25].x + 0.5);\n    float _3114 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3119 = _3104 > 0;\n    bool _3128;\n    if (_3119)\n    {\n        int param = _3104 - 1;\n        _3128 = _3114 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3128 = _3119;\n    }\n    if (_3128)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3134 = _3104 > 1;\n        bool _3141;\n        if (_3134)\n        {\n            _3141 = _3114 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3141 = _3134;\n        }\n        if (_3141)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3147 = _3104 > 2;\n        bool _3154;\n        if (_3147)\n        {\n            _3154 = _3114 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3154 = _3147;\n        }\n        if (_3154)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3160 = _3104 > 3;\n        bool _3167;\n        if (_3160)\n        {\n            _3167 = _3114 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3167 = _3160;\n        }\n        if (_3167)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6617 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6617 = -_6617;\n    }\n    vec3 _6240 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6617, fa_world_tangent, fa_uv, fa_vertex_color, _6240, gl_FrontFacing);\n    Surface _6248 = fa_standard_surface(param_1);\n    vec3 _6656 = _6248.albedo;\n    float _6657 = _6248.alpha;\n    vec3 _6658 = _6248.normal;\n    float _6659 = _6248.metallic;\n    float _6660 = _6248.roughness;\n    float _6661 = _6248.occlusion;\n    vec3 _6662 = _6248.emission;\n    float _6663 = _6248.clearcoat;\n    float _6664 = _6248.clearcoat_roughness;\n    vec3 _6665 = _6248.sheen_color;\n    float _6666 = _6248.sheen_roughness;\n    float _6667 = _6248.anisotropy;\n    float _6668 = _6248.anisotropy_rotation;\n    float _6669 = _6248.specular;\n    float _6670 = _6248.ior;\n    vec3 _6671 = _6248.specular_color;\n    float _6672 = _6248.transmission;\n    float _6673 = _6248.thickness;\n    vec3 _6674 = _6248.attenuation_color;\n    float _6675 = _6248.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6617, fa_world_tangent, fa_uv, fa_vertex_color, _6240, gl_FrontFacing);\n    Surface param_3 = _6248;\n    surface(param_2, param_3);\n    _6656 = param_3.albedo;\n    _6657 = param_3.alpha;\n    _6658 = param_3.normal;\n    _6659 = param_3.metallic;\n    _6660 = param_3.roughness;\n    _6661 = param_3.occlusion;\n    _6662 = param_3.emission;\n    _6663 = param_3.clearcoat;\n    _6664 = param_3.clearcoat_roughness;\n    _6665 = param_3.sheen_color;\n    _6666 = param_3.sheen_roughness;\n    _6667 = param_3.anisotropy;\n    _6668 = param_3.anisotropy_rotation;\n    _6669 = param_3.specular;\n    _6670 = param_3.ior;\n    _6671 = param_3.specular_color;\n    _6672 = param_3.transmission;\n    _6673 = param_3.thickness;\n    _6674 = param_3.attenuation_color;\n    _6675 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6617;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6656 = param_6;\n    _6658 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6656;\n    }\n    else\n    {\n        vec3 _6287 = _6658;\n        vec3 _6288 = normalize(_6287);\n        _6658 = _6288;\n        vec3 param_8 = _6288;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _6617, fa_world_tangent, fa_uv, fa_vertex_color, _6240, gl_FrontFacing);\n        Surface param_10 = Surface(_6656, _6657, _6658, _6659, _6660, _6661, _6662, _6663, _6664, _6665, _6666, _6667, _6668, _6669, _6670, _6671, _6672, _6673, _6674, _6675);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6307 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6307; ln++)\n        {\n            int param_12 = ln;\n            int _6320 = fa_cl_light(param_12);\n            int param_13 = _6320;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6320;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _6617;\n            LightSample _6336 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _6617, fa_world_tangent, fa_uv, fa_vertex_color, _6240, gl_FrontFacing);\n            Surface param_18 = Surface(_6656, _6657, _6658, _6659, _6660, _6661, _6662, _6663, _6664, _6665, _6666, _6667, _6668, _6669, _6670, _6671, _6672, _6673, _6674, _6675);\n            LightSample param_19 = _6336;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6351 = result;\n    vec3 _6352 = _6351 + _6662;\n    result = _6352;\n    vec3 param_20 = _6352;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6361 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6368;\n    if (!_6361)\n    {\n        _6368 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6368 = _6361;\n    }\n    if (_6368)\n    {\n        vec3 _6377 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6383 = dot(_6377, fa_mesh_fs_params[9].xyz);\n        bool _6387 = fa_mesh_fs_params[9].w > 0.5;\n        float _6388;\n        if (_6387)\n        {\n            _6388 = _6383;\n        }\n        else\n        {\n            _6388 = length(_6377);\n        }\n        float _6400 = _6388 - fa_mesh_fs_params[8].x;\n        if (_6400 > 0.0)\n        {\n            float _6409 = fa_mesh_fs_params[7].w * _6400;\n            float tau = _6409 * _6409;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6425;\n                if (_6387)\n                {\n                    _6425 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6383);\n                }\n                else\n                {\n                    _6425 = fa_mesh_fs_params[0].y;\n                }\n                float _6446 = mix(_6425, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6388, 0.0, 1.0));\n                float _6450 = fa_world_pos.y - _6446;\n                float _6455 = _6446 - fa_mesh_fs_params[8].z;\n                float _6460 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6463 = _6455 <= 0.0;\n                bool _6464 = !_6463;\n                bool _6470;\n                if (_6464)\n                {\n                    _6470 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6470 = _6463;\n                }\n                float _6471;\n                if (_6470)\n                {\n                    _6471 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6471 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6455, 80.0));\n                }\n                bool _6498;\n                if (_6464)\n                {\n                    _6498 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6498 = _6463;\n                }\n                float _6499;\n                if (_6498)\n                {\n                    _6499 = fa_mesh_fs_params[8].y * _6455;\n                }\n                else\n                {\n                    _6499 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6455, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6524 = _6460 <= 0.0;\n                bool _6531;\n                if (!_6524)\n                {\n                    _6531 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6531 = _6524;\n                }\n                float _6532;\n                if (_6531)\n                {\n                    _6532 = fa_mesh_fs_params[8].y * _6460;\n                }\n                else\n                {\n                    _6532 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6460, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6559;\n                if (abs(_6450) < 0.001000000047497451305389404296875)\n                {\n                    _6559 = _6471;\n                }\n                else\n                {\n                    _6559 = (_6532 - _6499) / _6450;\n                }\n                tau += (_6400 * max(_6559, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6657);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _828 = base_t;\n    _828.x = _227.x;\n    _828.y = _227.y;\n    _828.z = _227.z;\n    base_t = _828;\n    vec4 _243 = (_828 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _783 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _836 = _281;\n        _836.x = _286.x;\n        _836.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _839 = mrt;\n    _839.x = _315.x;\n    _839.y = _315.y;\n    _839.z = _315.z;\n    mrt = _839;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _788 = fa_mesh_fs_params[20].x;\n    float _789 = fa_mesh_fs_params[20].y;\n    float _792 = fa_mesh_fs_params[20].z;\n    float _791 = fa_mesh_fs_params[21].w;\n    float _794 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _788 *= _357.y;\n            _789 *= _357.z;\n            _791 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _783, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _788, _789, fa_mesh_fs_params[21].xyz, _791, _792, fa_mesh_fs_params[20].w, _794, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _678 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_215",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _828 = base_t;\n    _828.x = _227.x;\n    _828.y = _227.y;\n    _828.z = _227.z;\n    base_t = _828;\n    vec4 _243 = (_828 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _783 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _836 = _281;\n        _836.x = _286.x;\n        _836.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _836;\n        _783 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _839 = mrt;\n    _839.x = _315.x;\n    _839.y = _315.y;\n    _839.z = _315.z;\n    mrt = _839;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _788 = fa_mesh_fs_params[20].x;\n    float _789 = fa_mesh_fs_params[20].y;\n    float _792 = fa_mesh_fs_params[20].z;\n    float _791 = fa_mesh_fs_params[21].w;\n    float _794 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _788 *= _357.y;\n            _789 *= _357.z;\n            _791 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _792 *= mrt.x;\n            _794 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _783, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _788, _789, fa_mesh_fs_params[21].xyz, _791, _792, fa_mesh_fs_params[20].w, _794, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _678 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _678 = -_678;\n    }\n    vec3 _540 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _678, fa_world_tangent, fa_uv, fa_vertex_color, _540, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _555 = normalize(param_2.normal);\n    vec3 _570 = normalize(vec3(dot(fa_pre_r0, _555), dot(fa_pre_r1, _555), dot(fa_pre_r2, _555)));\n    float _582 = _570.z;\n    vec2 e = _570.xy / vec2((abs(_570.x) + abs(_570.y)) + abs(_582));\n    if (_582 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_215",
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
    }
  }
}
