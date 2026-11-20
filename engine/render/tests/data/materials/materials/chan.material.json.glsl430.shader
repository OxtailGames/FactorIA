{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "4155841b00106f1351e36fe7e96d502ece90660dd797ea3c7df876d511a0f129",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "vertexAttributes": [
    "color1",
    "uv1"
  ],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 9) in vec2 fa_attr_uv1;\nlayout(location = 10) in vec4 fa_attr_color1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nvec4 vertex_color1;\nvec2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3((fa_attr_uv1 * fa_mesh_vs_params[10].xy) + fa_mesh_vs_params[10].zw, float(fa_mesh_vs_params[10].x > 0.0));\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3692[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[41];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1533 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1540;\n    if (!_1533)\n    {\n        _1540 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1540 = _1533;\n    }\n    bool _1548;\n    if (!_1540)\n    {\n        _1548 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1548 = _1540;\n    }\n    bool _1555;\n    if (!_1548)\n    {\n        _1555 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1555 = _1548;\n    }\n    bool _1562;\n    if (!_1555)\n    {\n        _1562 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1562 = _1555;\n    }\n    if (_1562)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1572 = vec4(world_pos, 1.0);\n    float _1578 = dot(fa_mesh_fs_params[16], _1572);\n    if (!(_1578 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1600 = vec2(dot(fa_mesh_fs_params[14], _1572), dot(fa_mesh_fs_params[15], _1572)) / vec2(_1578);\n    int _1604 = int(fa_mesh_fs_params[18].x);\n    int _1608 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1608) + clamp(int(floor(((_1600.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1608 - 1)) * _1604)) + clamp(int(floor(((_1600.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1604 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1684 = fa_cluster_texel(param);\n    return ivec2(int(_1684.x), int(_1684.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5153 = fa_cluster_lookup(param);\n    fa_cl_slot = _5153.x;\n    fa_cl_local = _5153.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6297 = fa_linear_to_srgb(param);\n        c = _6297;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6305 = fa_srgb_to_linear(param_1);\n            c = _6305;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _477;\n    if (i.front_facing)\n    {\n        _477 = i.world_normal;\n    }\n    else\n    {\n        _477 = -i.world_normal;\n    }\n    vec3 _501 = normalize(i.world_tangent.xyz - (_477 * dot(_477, i.world_tangent.xyz)));\n    vec3 _528 = normalize(((_501 * m.x) + ((cross(_477, _501) * i.world_tangent.w) * m.y)) + (_477 * m.z));\n    vec3 _531;\n    if (i.front_facing)\n    {\n        _531 = _528;\n    }\n    else\n    {\n        _531 = -_528;\n    }\n    return _531;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6336 = fa_tex_fix(param_2, param_3);\n    vec4 _7934 = base_t;\n    _7934.x = _6336.x;\n    _7934.y = _6336.y;\n    _7934.z = _6336.z;\n    base_t = _7934;\n    vec4 _6350 = (_7934 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7743 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6382 = fa_tex_fix(param_6, param_7);\n        vec3 _6385 = (_6382 * 2.0) - vec3(1.0);\n        vec2 _6390 = _6385.xy * fa_mesh_fs_params[6].x;\n        vec3 _7942 = _6385;\n        _7942.x = _6390.x;\n        _7942.y = _6390.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7942;\n        _7743 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6418 = fa_tex_fix(param_12, param_13);\n    vec4 _7945 = mrt;\n    _7945.x = _6418.x;\n    _7945.y = _6418.y;\n    _7945.z = _6418.z;\n    mrt = _7945;\n    vec4 _6446 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6446.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6457 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6487 = fa_tex_fix(param_20, param_21);\n    float _7748 = fa_mesh_fs_params[20].x;\n    float _7749 = fa_mesh_fs_params[20].y;\n    float _7752 = fa_mesh_fs_params[20].z;\n    float _7751 = fa_mesh_fs_params[21].w;\n    float _7754 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7748 *= _6457.y;\n            _7749 *= _6457.z;\n            _7751 *= _6446.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7752 *= mrt.x;\n            _7754 *= mrt.w;\n        }\n    }\n    return Surface(_6350.xyz, _6350.w, _7743, clamp(fa_mesh_fs_params[5].x * _6418.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6418.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6457.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6487), _7748, _7749, fa_mesh_fs_params[21].xyz, _7751, _7752, fa_mesh_fs_params[20].w, _7754, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1764 = rect.zw - rect.xy;\n    vec2 _1768 = _1764 * atlas;\n    vec2 _1772 = ddx * _1768;\n    vec2 _1776 = ddy * _1768;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1764), clamp(0.5 * log2(max(max(dot(_1772, _1772), dot(_1776, _1776)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1809 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1816;\n    if (!_1809)\n    {\n        _1816 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1816 = _1809;\n    }\n    if (_1816)\n    {\n        return;\n    }\n    vec3 _1822 = dFdx(world_pos);\n    vec3 _1825 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1829 = fa_cluster_texel(param);\n    int _1833 = int(_1829.w);\n    if (_1833 < 1)\n    {\n        return;\n    }\n    int _1843 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1843;\n    vec4 _1847 = fa_light_texel(param_1);\n    vec2 _1850 = _1847.yz;\n    int _1854 = int(_1847.w);\n    int param_2 = _1843 + 1;\n    vec4 _1859 = fa_light_texel(param_2);\n    float _1860 = _1859.x;\n    int _1866 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1870 = int(_1829.z);\n    vec3 _2135;\n    for (int k = 0; k < _1833; k++)\n    {\n        int _1883 = _1870 + k;\n        int param_3 = _1854 + (_1883 >> 2);\n        int _1900 = (_1843 + 2) + (int(fa_light_texel(param_3)[_1883 & 3]) * 7);\n        int param_4 = _1900 + 6;\n        vec4 _1905 = fa_light_texel(param_4);\n        if (((int(_1905.w + 0.5) >> _1866) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1900;\n        vec4 _1920 = fa_light_texel(param_5);\n        int param_6 = _1900 + 1;\n        vec4 _1925 = fa_light_texel(param_6);\n        int param_7 = _1900 + 2;\n        vec4 _1930 = fa_light_texel(param_7);\n        vec3 _1933 = _1920.xyz;\n        float _1938 = dot(_1933, world_pos) + _1920.w;\n        vec3 _1940 = _1925.xyz;\n        float _1945 = dot(_1940, world_pos) + _1925.w;\n        vec3 _1947 = _1930.xyz;\n        float _1952 = dot(_1947, world_pos) + _1930.w;\n        bool _1957 = abs(_1938) > 0.5;\n        bool _1965;\n        if (!_1957)\n        {\n            _1965 = abs(_1945) > 0.5;\n        }\n        else\n        {\n            _1965 = _1957;\n        }\n        bool _1973;\n        if (!_1965)\n        {\n            _1973 = abs(_1952) > 0.5;\n        }\n        else\n        {\n            _1973 = _1965;\n        }\n        if (_1973)\n        {\n            continue;\n        }\n        float _1988 = clamp(dot(geo_normal, normalize(_1947)) * _1905.z, 0.0, 1.0);\n        if (_1988 <= 0.0)\n        {\n            continue;\n        }\n        float _2008 = (clamp((0.5 - abs(_1952)) * 10.0, 0.0, 1.0) * _1988) * _1905.x;\n        vec2 _2016 = vec2(_1938 + 0.5, 0.5 - _1945);\n        vec2 _2026 = vec2(dot(_1933, _1822), dot(_1940, _1822));\n        vec2 _2036 = vec2(dot(_1933, _1825), dot(_1940, _1825));\n        int param_8 = _1900 + 5;\n        vec4 _2041 = fa_light_texel(param_8);\n        int param_9 = _1900 + 3;\n        vec4 _2046 = fa_light_texel(param_9);\n        int param_10 = _1900 + 4;\n        vec4 _2051 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2041.xyz;\n        bool _2061 = _2046.z > _2046.x;\n        if (_2061)\n        {\n            vec4 param_11 = _2046;\n            vec2 param_12 = _2016;\n            vec2 param_13 = _1850;\n            vec2 param_14 = _2026;\n            vec2 param_15 = _2036;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1860 > 0.5) && (_1860 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2087 = fa_dc_to_linear(param_16);\n                vec4 _7831 = tx;\n                _7831.x = _2087.x;\n                _7831.y = _2087.y;\n                _7831.z = _2087.z;\n                tx = _7831;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2008 * tex_a) * _2041.w, 0.0, 1.0)));\n        if (_2051.z > _2051.x)\n        {\n            vec4 param_17 = _2051;\n            vec2 param_18 = _2016;\n            vec2 param_19 = _1850;\n            vec2 param_20 = _2026;\n            vec2 param_21 = _2036;\n            vec4 _2131 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1860 > 1.5)\n            {\n                vec3 param_22 = _2131.xyz;\n                vec3 _2141 = fa_dc_to_srgb(param_22);\n                _2135 = _2141;\n            }\n            else\n            {\n                _2135 = _2131.xyz;\n            }\n            vec3 _2150 = (_2135 * 2.0) - vec3(1.0);\n            vec2 _2155 = _2150.xy * _1905.y;\n            vec3 _2177 = (normalize(_1933) * _2155.x) + (normalize(_1940) * _2155.y);\n            vec3 _2180 = normalize(normal);\n            normal = normalize(mix(_2180, normalize((_2180 * max(_2150.z, 0.0500000007450580596923828125)) + (_2177 - (_2180 * dot(_2180, _2177)))), vec3(clamp(_2008 * (_2061 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3618 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3625 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3628 = int(_3618);\n    int _3631 = int(_3625);\n    float _3641 = _3625 - float(_3631);\n    int _3696 = (_3628 * 9) + _3631;\n    int _3716 = ((_3628 + 1) * 9) + _3631;\n    return mix(mix(_3692[_3696], _3692[_3696 + 1], _3641), mix(_3692[_3716], _3692[_3716 + 1], _3641), _3618 - float(_3628));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7666 = false;\n    float _7667 = 1.0;\n    float _7668 = 1.0;\n    float _7669 = 1.0;\n    float _7670 = 0.0;\n    float _7671 = 0.0;\n    float _7672 = 0.0;\n    float _7673 = 0.0;\n    float _7675 = 1.0;\n    bool _7676 = false;\n    vec3 _7677 = vec3(0.0);\n    float _7678 = 1.0;\n    float _7679 = 1.0;\n    float _7680 = 1.0;\n    float _7681 = 0.0;\n    float _7682 = 0.0;\n    vec3 _7683 = vec3(1.0, 0.0, 0.0);\n    vec3 _7684 = vec3(0.0, 0.0, 1.0);\n    float _7685 = 1.0;\n    float _7686 = 1.0;\n    float _3767 = clamp(s.specular, 0.0, 1.0);\n    float _3771 = clamp(s.ior, 1.0, 3.0);\n    bool _3776 = (_3767 != 1.0) || (_3771 != 1.5);\n    bool _3785;\n    if (!_3776)\n    {\n        _3785 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3785 = _3776;\n    }\n    if (_3785)\n    {\n        float _3793 = (_3771 - 1.0) / (_3771 + 1.0);\n        f0 = mix(min(vec3(_3793 * _3793) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3767, s.albedo, vec3(metallic));\n        _7667 = mix(_3767, 1.0, metallic);\n        _7666 = true;\n    }\n    float _3820 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3820 > 0.0)\n    {\n        float _3828 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7670 = _3820;\n        _7671 = _3828;\n        float _3835 = _3828 * _3828;\n        _7672 = _3835;\n        _7673 = _3835 * _3835;\n        float _3847 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7675 = _3847;\n        _7668 = 1.0 - (_3820 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3847, 0.0, 1.0), 5.0))));\n        _7666 = true;\n    }\n    vec3 _3866 = max(s.sheen_color, vec3(0.0));\n    float _3875 = max(_3866.x, max(_3866.y, _3866.z));\n    if (_3875 > 0.0)\n    {\n        float _3883 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7676 = true;\n        _7677 = _3866;\n        _7678 = _3883;\n        _7679 = _3883 * _3883;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3883;\n        float _3900 = fa_sheen_albedo(param, param_1);\n        _7681 = _3900;\n        _7680 = 1.0 - min(_3875 * _3900, 1.0);\n        _7666 = true;\n    }\n    _7669 = _7668 * _7680;\n    float _3919 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3919 != 0.0)\n    {\n        vec3 _3934 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3934;\n        if (dot(_3934, _3934) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3946 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3946.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3946.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3946.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3950 = t;\n        vec3 _3951 = normalize(_3950);\n        t = _3951;\n        vec3 _3976 = normalize((_3951 * cos(s.anisotropy_rotation)) + ((cross(n, _3951) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7683 = _3976;\n        _7684 = cross(n, _3976);\n        float _3986 = roughness * roughness;\n        float _3992 = mix(_3986, 1.0, _3919 * _3919);\n        bool _3994 = _3919 > 0.0;\n        _7685 = _3994 ? _3992 : _3986;\n        _7686 = _3994 ? _3986 : _3992;\n        _7682 = _3919;\n        _7666 = true;\n    }\n    return FaLayers(_7666, _7667, _7668, _7669, _7670, _7671, _7672, _7673, i.world_normal, _7675, _7676, _7677, _7678, _7679, _7680, _7681, _7682, _7683, _7684, _7685, _7686);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3375 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3375;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5123;\n    if (fa_lm.z > 0.5)\n    {\n        _5123 = 0.0;\n    }\n    else\n    {\n        _5123 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5134 = _5123 < 1.0;\n    bool _5140;\n    if (_5134)\n    {\n        int param = li;\n        _5140 = fa_light_baked(param);\n    }\n    else\n    {\n        _5140 = _5134;\n    }\n    return _5140 ? _5123 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _782 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _795 = (c - (ru * hx)) - p;\n        vec3 _801 = ru * (2.0 * hx);\n        float _807 = max(dot(_801, _801), 9.9999999392252902907785028219223e-09);\n        float _811 = dot(_795, _801);\n        float t = clamp((-_811) / _807, 0.0, 1.0);\n        if (_782)\n        {\n            float _826 = dot(r, _801);\n            float _832 = _807 - (_826 * _826);\n            if (abs(_832) > (9.9999997473787516355514526367188e-06 * _807))\n            {\n                t = clamp(((dot(r, _795) * _826) - _811) / _832, 0.0, 1.0);\n            }\n        }\n        return (p + _795) + (_801 * t);\n    }\n    vec3 q = p;\n    float _864 = dot(r, axis);\n    bool _872;\n    if (_782)\n    {\n        _872 = abs(_864) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _872 = _782;\n    }\n    if (_872)\n    {\n        float _882 = dot(c - p, axis) / _864;\n        if (_882 > 0.0)\n        {\n            q = p + (r * _882);\n        }\n    }\n    vec3 _895 = q - c;\n    vec2 xy = vec2(dot(_895, ru), dot(_895, uu));\n    if (shape > 0.5)\n    {\n        float _910 = length(xy);\n        if (_910 > hx)\n        {\n            xy *= (hx / _910);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _543 = abs(d);\n    float _545 = _543.x;\n    float _547 = _543.y;\n    bool _548 = _545 >= _547;\n    bool _556;\n    if (_548)\n    {\n        _556 = _545 >= _543.z;\n    }\n    else\n    {\n        _556 = _548;\n    }\n    int _557;\n    if (_556)\n    {\n        _557 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _572;\n        if (_547 >= _543.z)\n        {\n            _572 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _572 = (d.z > 0.0) ? 4 : 5;\n        }\n        _557 = _572;\n    }\n    return _557;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _702 = dot(d, right);\n    float _706 = dot(d, up);\n    float _717;\n    if (((_702 * _702) + (_706 * _706)) > 1.0000000133514319600180897396058e-10)\n    {\n        _717 = atan(_706, _702) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _717 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_717 - floor(_717)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _948 = fa_light_base(param);\n    bool _952 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _948;\n    vec4 _956 = fa_light_texel(param_1);\n    int param_2 = _948 + 1;\n    vec4 _961 = fa_light_texel(param_2);\n    float _964 = _961.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _976 = _952 && (_964 > 2.5);\n    fa_light_is_area = _976;\n    bool _978 = _964 < 0.5;\n    vec3 l;\n    if (_978)\n    {\n        l = normalize(_956.xyz);\n        if (_952)\n        {\n            int param_3 = _948 + 6;\n            vec4 _992 = fa_light_texel(param_3);\n            if (_992.z > 0.5)\n            {\n                int param_4 = _948 + 4;\n                vec4 _1002 = fa_light_texel(param_4);\n                int param_5 = _948 + 5;\n                vec4 _1007 = fa_light_texel(param_5);\n                vec2 param_6 = _992.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1002.xyz) * _1002.w, (-dot(world_pos, _1007.xyz)) * _1007.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1037 = _956.xyz;\n        vec3 _1039 = _1037 - world_pos;\n        vec3 to_light = _1039;\n        float _1042 = length(_1039);\n        float reach = _1042;\n        bool front = true;\n        if (_976)\n        {\n            int param_8 = _948 + 7;\n            reach = max(_1042 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _948 + 4;\n            vec4 _1066 = fa_light_texel(param_9);\n            int param_10 = _948 + 5;\n            vec4 _1071 = fa_light_texel(param_10);\n            int param_11 = _948 + 6;\n            vec4 _1076 = fa_light_texel(param_11);\n            float _1077 = _1076.w;\n            int param_12 = _948 + 2;\n            vec3 _1084 = normalize(fa_light_texel(param_12).xyz);\n            bool _1086 = _1077 > 1.5;\n            bool _1094;\n            if (!_1086)\n            {\n                _1094 = dot(_1084, to_light) < 0.0;\n            }\n            else\n            {\n                _1094 = _1086;\n            }\n            front = _1094;\n            vec3 r = vec3(0.0);\n            vec3 _1103 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1107 = dot(n, n) > 0.5;\n            bool _1115;\n            if (_1107)\n            {\n                _1115 = dot(_1103, _1103) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1115 = _1107;\n            }\n            if (_1115)\n            {\n                r = reflect(-normalize(_1103), normalize(n));\n            }\n            vec3 param_13 = _1037;\n            vec3 param_14 = _1084;\n            vec3 param_15 = _1066.xyz;\n            vec3 param_16 = _1071.xyz;\n            float param_17 = _1066.w;\n            float param_18 = _1071.w;\n            float param_19 = _1077;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1151 = length(to_light);\n        dist = _1151;\n        l = to_light / vec3(max(_1151, 9.9999997473787516355514526367188e-05));\n        float _1165 = reach / max(_956.w, 0.001000000047497451305389404296875);\n        float _1171 = clamp(1.0 - (_1165 * _1165), 0.0, 1.0);\n        float _1173;\n        if (front)\n        {\n            _1173 = _1171 * _1171;\n        }\n        else\n        {\n            _1173 = 0.0;\n        }\n        atten = _1173;\n        bool _1184 = _964 < 2.5;\n        if ((_964 > 1.5) && _1184)\n        {\n            int param_22 = _948 + 2;\n            vec4 _1192 = fa_light_texel(param_22);\n            float _1202 = _1192.w;\n            int param_23 = _948 + 3;\n            vec4 _1207 = fa_light_texel(param_23);\n            float _1208 = _1207.x;\n            float cos_inner = _1208;\n            if (_1208 > 1.5)\n            {\n                cos_inner = mix(_1202, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1202, cos_inner, dot(-l, normalize(_1192.xyz)));\n        }\n        if (_952 && (_964 < 1.5))\n        {\n            int param_24 = _948 + 6;\n            vec4 _1232 = fa_light_texel(param_24);\n            if (_1232.z > 0.5)\n            {\n                vec3 _1240 = -to_light;\n                int param_25 = _948 + 4;\n                int param_26 = _948 + 5;\n                vec3 _1254 = fa_light_texel(param_25).xyz;\n                vec3 _1258 = fa_light_texel(param_26).xyz;\n                vec3 _1267 = vec3(dot(_1240, _1254), dot(_1240, _1258), dot(_1240, cross(_1254, _1258)));\n                vec3 param_27 = _1267;\n                int _1271 = fa_cube_face(param_27);\n                int param_28 = _1271;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1298 = vec2(dot(_1267, cross(param_29, param_30)), dot(_1267, param_30)) / vec2(max(dot(_1267, param_29), 9.9999997473787516355514526367188e-05));\n                int _1302 = _1271 / 3;\n                vec2 param_31 = _1232.xy + (vec2(float(_1271 - (_1302 * 3)), float(_1302)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1298.x), 0.5 - (0.5 * _1298.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _948 + 7;\n            vec4 _1332 = fa_light_texel(param_33);\n            if (_1332.z > 0.5)\n            {\n                int param_34 = _948 + 2;\n                int param_35 = _948 + 4;\n                int param_36 = _948 + 5;\n                vec2 param_37 = _1332.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_952 && _1184)\n            {\n                int param_42 = _948 + 6;\n                vec4 _1379 = fa_light_texel(param_42);\n                int param_43 = _948 + 7;\n                vec4 _1384 = fa_light_texel(param_43);\n                bool _1387 = _1379.z > 0.5;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = _1384.z > 0.5;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                if (_1394)\n                {\n                    int param_44 = _948 + 2;\n                    vec4 _1401 = fa_light_texel(param_44);\n                    vec3 _1405 = normalize(_1401.xyz);\n                    int param_45 = _948 + 4;\n                    vec4 _1410 = fa_light_texel(param_45);\n                    int param_46 = _948 + 5;\n                    vec4 _1415 = fa_light_texel(param_46);\n                    if (_1387)\n                    {\n                        vec3 _1423 = -to_light;\n                        float _1430 = _1401.w;\n                        float _1446 = 0.5 / max(dot(_1423, _1405) * (sqrt(max(1.0 - (_1430 * _1430), 0.0)) / max(_1430, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1379.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1423, _1410.xyz) * _1446), 0.5 - (dot(_1423, _1415.xyz) * _1446));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1384.z > 0.5)\n                    {\n                        vec2 param_49 = _1384.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1405;\n                        vec3 param_52 = _1410.xyz;\n                        vec3 param_53 = _1415.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7654 = _961.xyz * atten;\n    if (_952)\n    {\n        _7654 *= fa_light_tint;\n    }\n    int _1515;\n    if (_978)\n    {\n        _1515 = 0;\n    }\n    else\n    {\n        _1515 = ((_964 > 1.5) && (_964 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7654, atten, 1.0, dist, _1515);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2252;\n    if (i == 0)\n    {\n        _2252 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2268;\n        if (i == 1)\n        {\n            _2268 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2276;\n            if (i == 2)\n            {\n                _2276 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2276 = fa_shadows[24].w;\n            }\n            _2268 = _2276;\n        }\n        _2252 = _2268;\n    }\n    return _2252;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2309 = fa_shadow_depth(param, param_1);\n    float _2313;\n    if (conv.x < 0.5)\n    {\n        _2313 = _2309;\n    }\n    else\n    {\n        _2313 = (conv.y * conv.z) / (conv.z - (_2309 * (conv.z - conv.y)));\n    }\n    return _2313;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2240 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2240), sin(_2240)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2359 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2368;\n        if (k < 0.0)\n        {\n            _2368 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2368 = k;\n        }\n        float _2388 = clamp((_2368 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2359;\n            vec2 _2407 = fa_shadow_vogel(param_3, param_4, param_5) * _2388;\n            vec2 param_6 = uv + (_2407 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2419 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2419 < (zr - (length(_2407) * plane)))\n            {\n                sum += _2419;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2445 = sum / cnt;\n        float _2455;\n        if (k < 0.0)\n        {\n            _2455 = (-k) / max(_2445, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2455 = k;\n        }\n        radius = clamp(((max(zr - _2445, 0.0) * unit) * _2455) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2477 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2477; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2477;\n        float param_11 = _2359;\n        vec2 _2496 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2496 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2496) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2477);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2538 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2543 = clamp(dot(n, l), 0.0, 1.0);\n    float _2549 = sqrt(1.0 - (_2543 * _2543));\n    float _2556 = min(_2549 / max(_2543, 0.20000000298023223876953125), 4.0);\n    float _2561;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2561 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2561 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2586 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2561 * _2549)), 1.0);\n    float _2593 = _2586.x;\n    bool _2596 = _2593 < fa_shadows[ci * 1 + 16].x;\n    bool _2605;\n    if (!_2596)\n    {\n        _2605 = _2593 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2605 = _2596;\n    }\n    bool _2614;\n    if (!_2605)\n    {\n        _2614 = _2586.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2614 = _2605;\n    }\n    bool _2623;\n    if (!_2614)\n    {\n        _2623 = _2586.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2623 = _2614;\n    }\n    bool _2630;\n    if (!_2623)\n    {\n        _2630 = _2586.z > 1.0;\n    }\n    else\n    {\n        _2630 = _2623;\n    }\n    if (_2630)\n    {\n        return -1.0;\n    }\n    float _2638;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2638 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2638 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2586.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2586.z - ((_2638 * (1.0 + (0.5 * _2556))) / _2538);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2538;\n    float param_5 = _2538 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2556, 3.0)) * 0.5) / _2538;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3016 = int(fa_shadows[25].x + 0.5);\n    if (_3016 < 1)\n    {\n        return 1.0;\n    }\n    float _3031 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3016 - 1;\n    if (_3031 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3043 = _3016 > 1;\n    bool _3050;\n    if (_3043)\n    {\n        _3050 = _3031 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3050 = _3043;\n    }\n    if (_3050)\n    {\n        ci = 1;\n    }\n    bool _3054 = _3016 > 2;\n    bool _3061;\n    if (_3054)\n    {\n        _3061 = _3031 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3061 = _3054;\n    }\n    if (_3061)\n    {\n        ci = 2;\n    }\n    bool _3065 = _3016 > 3;\n    bool _3072;\n    if (_3065)\n    {\n        _3072 = _3031 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3072 = _3065;\n    }\n    if (_3072)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3016)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3098 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3098;\n        if (_3098 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3123;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3123 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3123 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3142 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3123, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3153 = clamp((_3031 - (fa_shadow_split_at(param_7) - _3142)) / _3142, 0.0, 1.0);\n        if (_3153 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3016)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3174 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3174;\n                if (_3174 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3153);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2696 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2703;\n    if (!_2696)\n    {\n        _2703 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2703 = _2696;\n    }\n    if (_2703)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2716 = fa_light_texel(param);\n    float _2717 = _2716.x;\n    if (_2717 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2726 = int(_2717 + 0.5);\n    int param_1 = _2726;\n    vec4 _2730 = fa_light_texel(param_1);\n    int param_2 = _2726 + 1;\n    vec4 _2735 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2738 = _2730.y;\n    if (_2738 > 0.0)\n    {\n        float _2755 = 1.0 - smoothstep(0.75 * _2738, _2738, length(world - fa_shadows[27].xyz));\n        fade = _2755;\n        if (_2755 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2730.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2779 = (_2726 + 2) + (face * 6);\n    int param_4 = _2779;\n    int param_5 = _2779 + 1;\n    int param_6 = _2779 + 3;\n    vec4 _2793 = fa_light_texel(param_6);\n    int param_7 = _2779 + 4;\n    vec4 _2798 = fa_light_texel(param_7);\n    int param_8 = _2779 + 5;\n    vec4 _2803 = fa_light_texel(param_8);\n    float _2815 = _2803.x * max(dot(_2793, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2820 = clamp(dot(n, l), 0.0, 1.0);\n    float _2843 = clamp(dot(n, _2793.xyz), -1.0, 1.0);\n    float _2862 = min(sqrt(1.0 - (_2843 * _2843)) / max(abs(dot(n, world - lpos)) / max(dot(_2793, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2865 = _2735.y;\n    float _2867;\n    if (_2865 > 0.0)\n    {\n        _2867 = _2865;\n    }\n    else\n    {\n        _2867 = 1.5 * _2815;\n    }\n    vec4 _2887 = vec4(world + (n * (_2867 * sqrt(1.0 - (_2820 * _2820)))), 1.0);\n    float _2891 = dot(_2793, _2887);\n    float _2894 = _2803.y;\n    if (_2891 < _2894)\n    {\n        return 1.0;\n    }\n    vec2 _2909 = vec2(dot(fa_light_texel(param_4), _2887), dot(fa_light_texel(param_5), _2887)) / vec2(_2891);\n    float _2911 = _2909.x;\n    bool _2914 = _2911 < _2798.x;\n    bool _2923;\n    if (!_2914)\n    {\n        _2923 = _2911 > _2798.z;\n    }\n    else\n    {\n        _2923 = _2914;\n    }\n    bool _2932;\n    if (!_2923)\n    {\n        _2932 = _2909.y < _2798.y;\n    }\n    else\n    {\n        _2932 = _2923;\n    }\n    bool _2941;\n    if (!_2932)\n    {\n        _2941 = _2909.y > _2798.w;\n    }\n    else\n    {\n        _2941 = _2932;\n    }\n    if (_2941)\n    {\n        return 1.0;\n    }\n    float _2947 = _2735.x;\n    float _2949;\n    if (_2947 > 0.0)\n    {\n        _2949 = _2947;\n    }\n    else\n    {\n        _2949 = 1.5 * _2815;\n    }\n    vec2 param_9 = _2909;\n    vec4 param_10 = _2798;\n    float param_11 = _2891 - (_2949 * (1.0 + (0.5 * _2862)));\n    float param_12 = _2815;\n    float param_13 = 1.0;\n    float param_14 = _2803.z * 0.25;\n    float param_15 = (_2815 * min(_2862, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2894, _2803.z);\n    int param_17 = int(_2730.z + 0.5);\n    float param_18 = _2730.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4504 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4511;\n    if (!_4504)\n    {\n        _4511 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4511 = _4504;\n    }\n    if (_4511)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4524 = fa_light_texel(param);\n    float _4525 = _4524.y;\n    float len = _4525;\n    if (_4525 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4537 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4547 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4537);\n    if (_4547 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4553 = len;\n    float _4556 = min(_4553, 0.89999997615814208984375 * dist);\n    len = _4556;\n    float _4561 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4537);\n    float _4566 = _4561 + (0.5 * _4556);\n    vec3 _4572 = world + (gn * _4561);\n    float _4574 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4638;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4589 = (float(k) + _4574) * 0.083333335816860198974609375;\n        vec3 _4597 = _4572 + (l * (_4589 * len));\n        vec4 _4603 = vec4(_4597, 1.0);\n        float _4609 = dot(fa_mesh_fs_params[28], _4603);\n        if (_4609 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4629 = vec2(dot(fa_mesh_fs_params[26], _4603), dot(fa_mesh_fs_params[27], _4603)) / vec2(_4609);\n        float _4633 = _4629.x * 0.5;\n        float _4634 = _4633 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4638 = (_4629.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4638 = 0.5 - (_4629.y * 0.5);\n        }\n        bool _4654 = _4634 < 0.0;\n        bool _4661;\n        if (!_4654)\n        {\n            _4661 = _4634 >= 1.0;\n        }\n        else\n        {\n            _4661 = _4654;\n        }\n        bool _4668;\n        if (!_4661)\n        {\n            _4668 = _4638 < 0.0;\n        }\n        else\n        {\n            _4668 = _4661;\n        }\n        bool _4675;\n        if (!_4668)\n        {\n            _4675 = _4638 >= 1.0;\n        }\n        else\n        {\n            _4675 = _4668;\n        }\n        if (_4675)\n        {\n            break;\n        }\n        vec4 _4694 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4634, _4638) * fa_mesh_fs_params[24].zw), 0);\n        if (_4694.w < 0.5)\n        {\n            continue;\n        }\n        float _4713 = (dot(fa_mesh_fs_params[29].xyz, _4597) + fa_mesh_fs_params[29].w) - _4694.x;\n        if ((_4713 > _4561) && (_4713 < _4566))\n        {\n            occ = max(occ, (1.0 - (_4589 * _4589)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4634, 0.5 - _4633), min(_4638, 1.0 - _4638))));\n        }\n    }\n    return 1.0 - (occ * _4547);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5179 = fa_baked_keep(param);\n    if (_5179 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5205 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7723 = _5205.color;\n    float _7724 = _5205.attenuation;\n    float _7725 = _5205.shadow;\n    bool _5208 = _5205.type == 0;\n    if (_5208 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5205.direction;\n        float _5219 = fa_shadow_factor(param_5, param_6);\n        _7725 = _5219;\n        _7723 *= _5219;\n    }\n    else\n    {\n        bool _5230 = _5205.type != 0;\n        bool _5236;\n        if (_5230)\n        {\n            _5236 = _7724 > 0.0;\n        }\n        else\n        {\n            _5236 = _5230;\n        }\n        if (_5236)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5205.direction;\n            float _5255 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7725 = _5255;\n            _7723 *= _5255;\n        }\n    }\n    bool _5265 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5271;\n    if (_5265)\n    {\n        _5271 = _7724 > 0.0;\n    }\n    else\n    {\n        _5271 = _5265;\n    }\n    if (_5271)\n    {\n        float _5278;\n        if (_5208)\n        {\n            _5278 = 1000000000.0;\n        }\n        else\n        {\n            _5278 = _5205._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5205.direction;\n        float param_18 = _5278;\n        float _5296 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7725 *= _5296;\n        _7723 *= _5296;\n    }\n    float _5309 = _7724;\n    float _5310 = _5309 * _5179;\n    _7724 = _5310;\n    vec3 _5314 = _7723;\n    vec3 _5315 = _5314 * _5179;\n    _7723 = _5315;\n    return LightSample(_5205.direction, _5315, _5310, _7725, _5205._distance, _5205.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5349 = v - (n * dot(v, n));\n    vec3 t = _5349;\n    float _5353 = dot(_5349, _5349);\n    float l2 = _5353;\n    if (_5353 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5363;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5363 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5363 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5363;\n        l2 = dot(_5363, _5363);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5398 = dot(a, a);\n    float _5402 = dot(b, b);\n    if ((_5398 < 1.0000000195414813782625560981111e-24) || (_5402 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5416 = a * inversesqrt(_5398);\n    vec3 _5421 = b * inversesqrt(_5402);\n    float _5425 = dot(_5416, _5421);\n    float _5428 = abs(_5425);\n    float g = (((((((((((0.0416471660137176513671875 * _5428) - 0.1924748718738555908203125) * _5428) + 0.4179156124591827392578125) * _5428) - 0.616057217121124267578125) * _5428) + 0.777722418308258056640625) * _5428) - 0.999542415142059326171875) * _5428) + 1.570791721343994140625;\n    if (_5425 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5425 * _5425), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5416, _5421) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5485 = a.z > 0.0;\n    bool _5489 = b.z > 0.0;\n    if (_5485 && _5489)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5485 != _5489)\n        {\n            vec3 _5524 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5524.z = 0.0;\n            if (_5485)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5524;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5524;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5524;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5524;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5573 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5599 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5625 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5651 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5573;\n    vec3 param_1 = _5599;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5599;\n    vec3 param_7 = _5625;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5625;\n    vec3 param_13 = _5651;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5651;\n    vec3 param_19 = _5573;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5800 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5824 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5840 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5800;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5824;\n    vec4 param_9 = m;\n    vec3 param_10 = _5800;\n    vec3 param_11 = _5824;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5840;\n    vec4 param_14 = m;\n    vec3 param_15 = _5800;\n    vec3 param_16 = _5840;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5898 = fa_light_base(param);\n    int param_1 = _5898;\n    int param_2 = _5898 + 1;\n    int param_3 = _5898 + 2;\n    int param_4 = _5898 + 4;\n    vec4 _5920 = fa_light_texel(param_4);\n    int param_5 = _5898 + 5;\n    vec4 _5925 = fa_light_texel(param_5);\n    int param_6 = _5898 + 6;\n    vec4 _5930 = fa_light_texel(param_6);\n    float _5931 = _5930.w;\n    vec3 _5936 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5938 = _5931 < 1.5;\n    bool _5945;\n    if (_5938)\n    {\n        _5945 = dot(normalize(fa_light_texel(param_3).xyz), _5936) >= 0.0;\n    }\n    else\n    {\n        _5945 = _5938;\n    }\n    if (_5945)\n    {\n        return vec3(0.0);\n    }\n    bool _5954 = (_5931 > 0.5) && _5938;\n    float _5958 = _5954 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5961 = _5920.xyz;\n    float _5963 = _5920.w;\n    vec3 _5969 = _5925.xyz;\n    float _5971 = _5925.w;\n    vec3 up = _5969 * (_5971 * _5958);\n    float _5977;\n    if (_5954)\n    {\n        _5977 = (3.1415927410125732421875 * _5963) * _5963;\n    }\n    else\n    {\n        _5977 = (4.0 * _5963) * _5971;\n    }\n    if (_5931 > 1.5)\n    {\n        vec3 _6003 = cross(_5961, -_5936);\n        vec3 perp = _6003;\n        float _6007 = dot(_6003, _6003);\n        vec3 _6010;\n        if (_6007 > 1.0000000133514319600180897396058e-10)\n        {\n            _6010 = perp * inversesqrt(_6007);\n        }\n        else\n        {\n            _6010 = _5969;\n        }\n        perp = _6010;\n        up = _6010 * _5971;\n    }\n    float _6031 = max(_5977, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6041 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6041;\n    vec3 param_10 = n;\n    vec3 param_11 = _5936;\n    vec3 _6049 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6041;\n    vec3 param_13 = n;\n    vec3 param_14 = _5961 * (_5963 * _5958);\n    vec3 _6057 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6041;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6065 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5931;\n    vec3 param_20 = _6049;\n    vec3 param_21 = _6057;\n    vec3 param_22 = _6065;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6084 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6084;\n    vec2 param_26 = _6084 + vec2(64.0, 0.0);\n    vec4 _6094 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5931;\n    vec3 param_29 = _6049;\n    vec3 param_30 = _6057;\n    vec3 param_31 = _6065;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6094.x) + ((vec3(f90) - f0) * _6094.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5936, _5936)) + _6031) / _6031) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4241 = 1.0 / alpha;\n    return ((2.0 + _4241) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4241)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4276 = max(dot(L.nc, l), 0.0);\n    float _4282 = max(dot(L.nc, h), 0.0);\n    float _4291 = ((_4282 * _4282) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4291) * _4291)) * (0.5 / max(mix((2.0 * _4276) * L.coat_ndv, _4276 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4276)) * _4276;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6162;\n    if (L.sheen_on)\n    {\n        _6162 = L.sheen_scale;\n    }\n    else\n    {\n        _6162 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6162);\n    vec3 _6175 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6186 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6195 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6175), 0.0);\n        float param_13 = _6195;\n        float param_14 = ndv;\n        result += ((L.sheen * _6186) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6195)) * _6195) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6175;\n        float param_18 = max(dot(v, _6175), 0.0);\n        result += (_6186 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4144 = tdh / at;\n    float _4148 = bdh / ab;\n    float _4160 = ((_4144 * _4144) + (_4148 * _4148)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4160) * _4160);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4340 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4419 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4419) * _4419);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4340);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4340));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3550 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3553 = _3550.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3553 * _3553, exp2((-9.27999973297119140625) * ndv)) * _3553) + _3550.y)) + _3550.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3404 = rough * rough;\n    float _3434 = 0.60000002384185791015625 * _3404;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3404)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3434, 0.0500000007450580596923828125 + _3434, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3404 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4027;\n        if (L.aniso >= 0.0)\n        {\n            _4027 = L.b;\n        }\n        else\n        {\n            _4027 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4027, v), _4027), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4060 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4060.x) + (vec3(L.f90) * _4060.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4115 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4115.x) + _4115.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3592 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3592.x) + vec3(_3592.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _4817 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _4821 = fa_xm_origin(param_1);\n    vec2 _4827 = (uv * _4817) - vec2(0.5);\n    vec2 _4830 = fract(_4827);\n    vec2 _4833 = floor(_4827);\n    vec2 param_2 = _4817;\n    vec2 param_3 = _4821;\n    vec2 param_4 = _4833;\n    vec2 param_5 = _4817;\n    vec2 param_6 = _4821;\n    vec2 param_7 = _4833 + vec2(1.0, 0.0);\n    vec2 param_8 = _4817;\n    vec2 param_9 = _4821;\n    vec2 param_10 = _4833 + vec2(0.0, 1.0);\n    vec2 param_11 = _4817;\n    vec2 param_12 = _4821;\n    vec2 param_13 = _4833 + vec2(1.0);\n    vec3 _4875 = vec3(_4830.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4875), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4875), vec3(_4830.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _4894 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _4898 = clamp(lod, 0.0, _4894);\n    int _4902 = int(floor(_4898));\n    int param = _4902;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _4912 = float(_4902);\n    float _4913 = _4898 - _4912;\n    bool _4915 = _4913 > 0.001000000047497451305389404296875;\n    bool _4922;\n    if (_4915)\n    {\n        _4922 = _4912 < _4894;\n    }\n    else\n    {\n        _4922 = _4915;\n    }\n    if (_4922)\n    {\n        int param_2 = _4902 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_4913));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4948 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _4948.x) + (vec3(f90) * _4948.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _4976 = max(s.thickness, 0.0);\n    bool _4981 = _4976 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _4981)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _4976);\n    }\n    bool _5006 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5013;\n    if (!_5006)\n    {\n        _5013 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5013 = _5006;\n    }\n    if (_5013)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_4981)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _4976);\n    }\n    vec4 _5048 = vec4(world, 1.0);\n    float _5053 = dot(fa_mesh_fs_params[28], _5048);\n    vec2 uv = vec2(0.5);\n    if (_5053 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5071 = vec2(dot(fa_mesh_fs_params[26], _5048), dot(fa_mesh_fs_params[27], _5048)) / vec2(_5053);\n        float _5079;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5079 = (_5071.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5079 = 0.5 - (_5071.y * 0.5);\n        }\n        uv = vec2((_5071.x * 0.5) + 0.5, _5079);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3198 = int(fa_shadows[25].x + 0.5);\n    float _3208 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3213 = _3198 > 0;\n    bool _3222;\n    if (_3213)\n    {\n        int param = _3198 - 1;\n        _3222 = _3208 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3222 = _3213;\n    }\n    if (_3222)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3228 = _3198 > 1;\n        bool _3235;\n        if (_3228)\n        {\n            _3235 = _3208 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3235 = _3228;\n        }\n        if (_3235)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3241 = _3198 > 2;\n        bool _3248;\n        if (_3241)\n        {\n            _3248 = _3208 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3248 = _3241;\n        }\n        if (_3248)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3254 = _3198 > 3;\n        bool _3261;\n        if (_3254)\n        {\n            _3261 = _3208 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3261 = _3254;\n        }\n        if (_3261)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7382 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7382 = -_7382;\n    }\n    vec3 _6677 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7382, fa_world_tangent, fa_uv, fa_vertex_color, _6677, gl_FrontFacing);\n    Surface _6685 = fa_standard_surface(param_1);\n    vec3 _7413 = _6685.albedo;\n    float _7414 = _6685.alpha;\n    vec3 _7415 = _6685.normal;\n    float _7416 = _6685.metallic;\n    float _7417 = _6685.roughness;\n    float _7418 = _6685.occlusion;\n    vec3 _7419 = _6685.emission;\n    float _7420 = _6685.clearcoat;\n    float _7421 = _6685.clearcoat_roughness;\n    vec3 _7422 = _6685.sheen_color;\n    float _7423 = _6685.sheen_roughness;\n    float _7424 = _6685.anisotropy;\n    float _7425 = _6685.anisotropy_rotation;\n    float _7426 = _6685.specular;\n    float _7427 = _6685.ior;\n    vec3 _7428 = _6685.specular_color;\n    float _7429 = _6685.transmission;\n    float _7430 = _6685.thickness;\n    vec3 _7431 = _6685.attenuation_color;\n    float _7432 = _6685.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7382, fa_world_tangent, fa_uv, fa_vertex_color, _6677, gl_FrontFacing);\n    Surface param_3 = _6685;\n    surface(param_2, param_3);\n    _7413 = param_3.albedo;\n    _7414 = param_3.alpha;\n    _7415 = param_3.normal;\n    _7416 = param_3.metallic;\n    _7417 = param_3.roughness;\n    _7418 = param_3.occlusion;\n    _7419 = param_3.emission;\n    _7420 = param_3.clearcoat;\n    _7421 = param_3.clearcoat_roughness;\n    _7422 = param_3.sheen_color;\n    _7423 = param_3.sheen_roughness;\n    _7424 = param_3.anisotropy;\n    _7425 = param_3.anisotropy_rotation;\n    _7426 = param_3.specular;\n    _7427 = param_3.ior;\n    _7428 = param_3.specular_color;\n    _7429 = param_3.transmission;\n    _7430 = param_3.thickness;\n    _7431 = param_3.attenuation_color;\n    _7432 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7382;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7413 = param_6;\n    _7415 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7413;\n    }\n    else\n    {\n        vec3 _6725 = normalize(_7415);\n        float _6732 = clamp(_7416, 0.0, 1.0);\n        float _6736 = clamp(_7417, 0.0500000007450580596923828125, 1.0);\n        float _6740 = _6736 * _6736;\n        float _6744 = _6740 * _6740;\n        float _6749 = max(dot(_6725, _6677), 9.9999997473787516355514526367188e-05);\n        float _6755 = 1.0 - _6732;\n        float _6756 = clamp(_7429, 0.0, 1.0) * _6755;\n        vec3 _6765 = (_7413 * _6755) * (1.0 - _6756);\n        vec3 _6772 = mix(vec3(0.039999999105930328369140625), _7413, vec3(_6732));\n        vec3 f0 = _6772;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7382, fa_world_tangent, fa_uv, fa_vertex_color, _6677, gl_FrontFacing);\n        Surface param_9 = Surface(_7413, _7414, _7415, _7416, _7417, _7418, _7419, _7420, _7421, _7422, _7423, _7424, _7425, _7426, _7427, _7428, _7429, _7430, _7431, _7432);\n        vec3 param_10 = _6725;\n        vec3 param_11 = _6677;\n        float param_12 = _6732;\n        float param_13 = _6736;\n        vec3 param_14 = _6772;\n        FaLayers _6788 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6725;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6765) * _7418;\n        if (_6788.on)\n        {\n            lit *= _6788.base_scale;\n        }\n        int _6810 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6810; ln++)\n        {\n            int param_16 = ln;\n            int _6823 = fa_cl_light(param_16);\n            int param_17 = _6823;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _6823;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7382;\n            LightSample _6839 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6847 = max(dot(_6725, _6839.direction), 0.0);\n            float _6853 = _6839.attenuation * _6839.shadow;\n            vec3 _6858 = normalize(_6839.direction + _6677);\n            float _6863 = max(dot(_6725, _6858), 0.0);\n            float _6868 = max(dot(_6677, _6858), 0.0);\n            bool _6875;\n            if (fa_light_is_area)\n            {\n                _6875 = !_6788.on;\n            }\n            else\n            {\n                _6875 = fa_light_is_area;\n            }\n            if (_6875)\n            {\n                int param_21 = _6823;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6725;\n                vec3 param_24 = _6677;\n                vec3 param_25 = _6765;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6736;\n                float param_29 = _6749;\n                float param_30 = _6853;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6788;\n                    int param_32 = _6823;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6725;\n                    vec3 param_35 = _6677;\n                    vec3 param_36 = _6839.direction;\n                    vec3 param_37 = _6765;\n                    vec3 param_38 = f0;\n                    float param_39 = _6736;\n                    float param_40 = _6749;\n                    float param_41 = _6853;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6788.on)\n                    {\n                        FaLayers param_42 = _6788;\n                        vec3 param_43 = _6765;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6725;\n                        vec3 param_46 = _6677;\n                        vec3 param_47 = _6839.direction;\n                        vec3 param_48 = _6858;\n                        float param_49 = _6847;\n                        float param_50 = _6749;\n                        float param_51 = _6863;\n                        float param_52 = _6868;\n                        float param_53 = _6740;\n                        float param_54 = _6744;\n                        int param_55 = _6823;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6853));\n                    }\n                    else\n                    {\n                        float _6981 = ((_6863 * _6863) * (_6744 - 1.0)) + 1.0;\n                        int param_56 = _6823;\n                        lit += (((_6765 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6868, 5.0))) * (((_6744 / ((3.1415927410125732421875 * _6981) * _6981)) * (0.5 / max(mix((2.0 * _6847) * _6749, _6847 + _6749, _6740), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6847))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6847 * _6853));\n                    }\n                }\n            }\n        }\n        if (_6788.on)\n        {\n            FaLayers param_57 = _6788;\n            vec3 param_58 = _6725;\n            vec3 param_59 = _6677;\n            vec3 param_60 = f0;\n            float param_61 = _6736;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7418);\n        }\n        else\n        {\n            vec3 param_62 = _6725;\n            vec3 param_63 = _6677;\n            vec3 param_64 = f0;\n            float param_65 = _6736;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7418);\n        }\n        if (_6756 > 0.0)\n        {\n            float _7079;\n            if (_6788.on)\n            {\n                _7079 = _6788.f90;\n            }\n            else\n            {\n                _7079 = 1.0;\n            }\n            float _7087;\n            if (_6788.on)\n            {\n                _7087 = _6788.base_scale;\n            }\n            else\n            {\n                _7087 = 1.0;\n            }\n            Surface param_66 = Surface(_7413, _7414, _7415, _7416, _7417, _7418, _7419, _7420, _7421, _7422, _7423, _7424, _7425, _7426, _7427, _7428, _7429, _7430, _7431, _7432);\n            vec3 param_67 = _6725;\n            vec3 param_68 = _6677;\n            float param_69 = _6736;\n            vec3 param_70 = f0;\n            float param_71 = _7079;\n            float param_72 = _7087;\n            float param_73 = _6756;\n            float param_74 = fa_tr_blend;\n            vec3 _7111 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7111;\n        }\n        result = lit;\n    }\n    vec3 _7118 = result;\n    vec3 _7119 = _7118 + _7419;\n    result = _7119;\n    vec3 param_75 = _7119;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7128 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7135;\n    if (!_7128)\n    {\n        _7135 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7135 = _7128;\n    }\n    if (_7135)\n    {\n        vec3 _7144 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7150 = dot(_7144, fa_mesh_fs_params[9].xyz);\n        bool _7154 = fa_mesh_fs_params[9].w > 0.5;\n        float _7155;\n        if (_7154)\n        {\n            _7155 = _7150;\n        }\n        else\n        {\n            _7155 = length(_7144);\n        }\n        float _7167 = _7155 - fa_mesh_fs_params[8].x;\n        if (_7167 > 0.0)\n        {\n            float _7176 = fa_mesh_fs_params[7].w * _7167;\n            float tau = _7176 * _7176;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7192;\n                if (_7154)\n                {\n                    _7192 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7150);\n                }\n                else\n                {\n                    _7192 = fa_mesh_fs_params[0].y;\n                }\n                float _7213 = mix(_7192, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7155, 0.0, 1.0));\n                float _7217 = fa_world_pos.y - _7213;\n                float _7222 = _7213 - fa_mesh_fs_params[8].z;\n                float _7227 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7230 = _7222 <= 0.0;\n                bool _7231 = !_7230;\n                bool _7237;\n                if (_7231)\n                {\n                    _7237 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7237 = _7230;\n                }\n                float _7238;\n                if (_7237)\n                {\n                    _7238 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7238 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7222, 80.0));\n                }\n                bool _7265;\n                if (_7231)\n                {\n                    _7265 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7265 = _7230;\n                }\n                float _7266;\n                if (_7265)\n                {\n                    _7266 = fa_mesh_fs_params[8].y * _7222;\n                }\n                else\n                {\n                    _7266 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7222, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7291 = _7227 <= 0.0;\n                bool _7298;\n                if (!_7291)\n                {\n                    _7298 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7298 = _7291;\n                }\n                float _7299;\n                if (_7298)\n                {\n                    _7299 = fa_mesh_fs_params[8].y * _7227;\n                }\n                else\n                {\n                    _7299 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7227, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7326;\n                if (abs(_7217) < 0.001000000047497451305389404296875)\n                {\n                    _7326 = _7238;\n                }\n                else\n                {\n                    _7326 = (_7299 - _7266) / _7217;\n                }\n                tau += (_7167 * max(_7326, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _7362 = 1.0 - fa_tr_blend;\n        result /= vec3(_7362);\n        _7414 *= _7362;\n    }\n    fa_frag_color = vec4(result, _7414);\n}\n\n",
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
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_attr_uv1"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_attr_color1"
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
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_595",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
            "inst_name": "_2262",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 11) in vec2 fa_attr_uv1;\nlayout(location = 12) in vec4 fa_attr_color1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nvec4 vertex_color1;\nvec2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_186 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_186 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_186 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3692[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[41];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1533 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1540;\n    if (!_1533)\n    {\n        _1540 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1540 = _1533;\n    }\n    bool _1548;\n    if (!_1540)\n    {\n        _1548 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1548 = _1540;\n    }\n    bool _1555;\n    if (!_1548)\n    {\n        _1555 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1555 = _1548;\n    }\n    bool _1562;\n    if (!_1555)\n    {\n        _1562 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1562 = _1555;\n    }\n    if (_1562)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1572 = vec4(world_pos, 1.0);\n    float _1578 = dot(fa_mesh_fs_params[16], _1572);\n    if (!(_1578 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1600 = vec2(dot(fa_mesh_fs_params[14], _1572), dot(fa_mesh_fs_params[15], _1572)) / vec2(_1578);\n    int _1604 = int(fa_mesh_fs_params[18].x);\n    int _1608 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1608) + clamp(int(floor(((_1600.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1608 - 1)) * _1604)) + clamp(int(floor(((_1600.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1604 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1684 = fa_cluster_texel(param);\n    return ivec2(int(_1684.x), int(_1684.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5153 = fa_cluster_lookup(param);\n    fa_cl_slot = _5153.x;\n    fa_cl_local = _5153.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6297 = fa_linear_to_srgb(param);\n        c = _6297;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6305 = fa_srgb_to_linear(param_1);\n            c = _6305;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _477;\n    if (i.front_facing)\n    {\n        _477 = i.world_normal;\n    }\n    else\n    {\n        _477 = -i.world_normal;\n    }\n    vec3 _501 = normalize(i.world_tangent.xyz - (_477 * dot(_477, i.world_tangent.xyz)));\n    vec3 _528 = normalize(((_501 * m.x) + ((cross(_477, _501) * i.world_tangent.w) * m.y)) + (_477 * m.z));\n    vec3 _531;\n    if (i.front_facing)\n    {\n        _531 = _528;\n    }\n    else\n    {\n        _531 = -_528;\n    }\n    return _531;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6336 = fa_tex_fix(param_2, param_3);\n    vec4 _7934 = base_t;\n    _7934.x = _6336.x;\n    _7934.y = _6336.y;\n    _7934.z = _6336.z;\n    base_t = _7934;\n    vec4 _6350 = (_7934 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7743 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6382 = fa_tex_fix(param_6, param_7);\n        vec3 _6385 = (_6382 * 2.0) - vec3(1.0);\n        vec2 _6390 = _6385.xy * fa_mesh_fs_params[6].x;\n        vec3 _7942 = _6385;\n        _7942.x = _6390.x;\n        _7942.y = _6390.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7942;\n        _7743 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6418 = fa_tex_fix(param_12, param_13);\n    vec4 _7945 = mrt;\n    _7945.x = _6418.x;\n    _7945.y = _6418.y;\n    _7945.z = _6418.z;\n    mrt = _7945;\n    vec4 _6446 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6446.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6457 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6487 = fa_tex_fix(param_20, param_21);\n    float _7748 = fa_mesh_fs_params[20].x;\n    float _7749 = fa_mesh_fs_params[20].y;\n    float _7752 = fa_mesh_fs_params[20].z;\n    float _7751 = fa_mesh_fs_params[21].w;\n    float _7754 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7748 *= _6457.y;\n            _7749 *= _6457.z;\n            _7751 *= _6446.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7752 *= mrt.x;\n            _7754 *= mrt.w;\n        }\n    }\n    return Surface(_6350.xyz, _6350.w, _7743, clamp(fa_mesh_fs_params[5].x * _6418.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6418.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6457.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6487), _7748, _7749, fa_mesh_fs_params[21].xyz, _7751, _7752, fa_mesh_fs_params[20].w, _7754, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1764 = rect.zw - rect.xy;\n    vec2 _1768 = _1764 * atlas;\n    vec2 _1772 = ddx * _1768;\n    vec2 _1776 = ddy * _1768;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1764), clamp(0.5 * log2(max(max(dot(_1772, _1772), dot(_1776, _1776)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1809 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1816;\n    if (!_1809)\n    {\n        _1816 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1816 = _1809;\n    }\n    if (_1816)\n    {\n        return;\n    }\n    vec3 _1822 = dFdx(world_pos);\n    vec3 _1825 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1829 = fa_cluster_texel(param);\n    int _1833 = int(_1829.w);\n    if (_1833 < 1)\n    {\n        return;\n    }\n    int _1843 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1843;\n    vec4 _1847 = fa_light_texel(param_1);\n    vec2 _1850 = _1847.yz;\n    int _1854 = int(_1847.w);\n    int param_2 = _1843 + 1;\n    vec4 _1859 = fa_light_texel(param_2);\n    float _1860 = _1859.x;\n    int _1866 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1870 = int(_1829.z);\n    vec3 _2135;\n    for (int k = 0; k < _1833; k++)\n    {\n        int _1883 = _1870 + k;\n        int param_3 = _1854 + (_1883 >> 2);\n        int _1900 = (_1843 + 2) + (int(fa_light_texel(param_3)[_1883 & 3]) * 7);\n        int param_4 = _1900 + 6;\n        vec4 _1905 = fa_light_texel(param_4);\n        if (((int(_1905.w + 0.5) >> _1866) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1900;\n        vec4 _1920 = fa_light_texel(param_5);\n        int param_6 = _1900 + 1;\n        vec4 _1925 = fa_light_texel(param_6);\n        int param_7 = _1900 + 2;\n        vec4 _1930 = fa_light_texel(param_7);\n        vec3 _1933 = _1920.xyz;\n        float _1938 = dot(_1933, world_pos) + _1920.w;\n        vec3 _1940 = _1925.xyz;\n        float _1945 = dot(_1940, world_pos) + _1925.w;\n        vec3 _1947 = _1930.xyz;\n        float _1952 = dot(_1947, world_pos) + _1930.w;\n        bool _1957 = abs(_1938) > 0.5;\n        bool _1965;\n        if (!_1957)\n        {\n            _1965 = abs(_1945) > 0.5;\n        }\n        else\n        {\n            _1965 = _1957;\n        }\n        bool _1973;\n        if (!_1965)\n        {\n            _1973 = abs(_1952) > 0.5;\n        }\n        else\n        {\n            _1973 = _1965;\n        }\n        if (_1973)\n        {\n            continue;\n        }\n        float _1988 = clamp(dot(geo_normal, normalize(_1947)) * _1905.z, 0.0, 1.0);\n        if (_1988 <= 0.0)\n        {\n            continue;\n        }\n        float _2008 = (clamp((0.5 - abs(_1952)) * 10.0, 0.0, 1.0) * _1988) * _1905.x;\n        vec2 _2016 = vec2(_1938 + 0.5, 0.5 - _1945);\n        vec2 _2026 = vec2(dot(_1933, _1822), dot(_1940, _1822));\n        vec2 _2036 = vec2(dot(_1933, _1825), dot(_1940, _1825));\n        int param_8 = _1900 + 5;\n        vec4 _2041 = fa_light_texel(param_8);\n        int param_9 = _1900 + 3;\n        vec4 _2046 = fa_light_texel(param_9);\n        int param_10 = _1900 + 4;\n        vec4 _2051 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2041.xyz;\n        bool _2061 = _2046.z > _2046.x;\n        if (_2061)\n        {\n            vec4 param_11 = _2046;\n            vec2 param_12 = _2016;\n            vec2 param_13 = _1850;\n            vec2 param_14 = _2026;\n            vec2 param_15 = _2036;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1860 > 0.5) && (_1860 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2087 = fa_dc_to_linear(param_16);\n                vec4 _7831 = tx;\n                _7831.x = _2087.x;\n                _7831.y = _2087.y;\n                _7831.z = _2087.z;\n                tx = _7831;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2008 * tex_a) * _2041.w, 0.0, 1.0)));\n        if (_2051.z > _2051.x)\n        {\n            vec4 param_17 = _2051;\n            vec2 param_18 = _2016;\n            vec2 param_19 = _1850;\n            vec2 param_20 = _2026;\n            vec2 param_21 = _2036;\n            vec4 _2131 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1860 > 1.5)\n            {\n                vec3 param_22 = _2131.xyz;\n                vec3 _2141 = fa_dc_to_srgb(param_22);\n                _2135 = _2141;\n            }\n            else\n            {\n                _2135 = _2131.xyz;\n            }\n            vec3 _2150 = (_2135 * 2.0) - vec3(1.0);\n            vec2 _2155 = _2150.xy * _1905.y;\n            vec3 _2177 = (normalize(_1933) * _2155.x) + (normalize(_1940) * _2155.y);\n            vec3 _2180 = normalize(normal);\n            normal = normalize(mix(_2180, normalize((_2180 * max(_2150.z, 0.0500000007450580596923828125)) + (_2177 - (_2180 * dot(_2180, _2177)))), vec3(clamp(_2008 * (_2061 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3618 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3625 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3628 = int(_3618);\n    int _3631 = int(_3625);\n    float _3641 = _3625 - float(_3631);\n    int _3696 = (_3628 * 9) + _3631;\n    int _3716 = ((_3628 + 1) * 9) + _3631;\n    return mix(mix(_3692[_3696], _3692[_3696 + 1], _3641), mix(_3692[_3716], _3692[_3716 + 1], _3641), _3618 - float(_3628));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7666 = false;\n    float _7667 = 1.0;\n    float _7668 = 1.0;\n    float _7669 = 1.0;\n    float _7670 = 0.0;\n    float _7671 = 0.0;\n    float _7672 = 0.0;\n    float _7673 = 0.0;\n    float _7675 = 1.0;\n    bool _7676 = false;\n    vec3 _7677 = vec3(0.0);\n    float _7678 = 1.0;\n    float _7679 = 1.0;\n    float _7680 = 1.0;\n    float _7681 = 0.0;\n    float _7682 = 0.0;\n    vec3 _7683 = vec3(1.0, 0.0, 0.0);\n    vec3 _7684 = vec3(0.0, 0.0, 1.0);\n    float _7685 = 1.0;\n    float _7686 = 1.0;\n    float _3767 = clamp(s.specular, 0.0, 1.0);\n    float _3771 = clamp(s.ior, 1.0, 3.0);\n    bool _3776 = (_3767 != 1.0) || (_3771 != 1.5);\n    bool _3785;\n    if (!_3776)\n    {\n        _3785 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3785 = _3776;\n    }\n    if (_3785)\n    {\n        float _3793 = (_3771 - 1.0) / (_3771 + 1.0);\n        f0 = mix(min(vec3(_3793 * _3793) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3767, s.albedo, vec3(metallic));\n        _7667 = mix(_3767, 1.0, metallic);\n        _7666 = true;\n    }\n    float _3820 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3820 > 0.0)\n    {\n        float _3828 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7670 = _3820;\n        _7671 = _3828;\n        float _3835 = _3828 * _3828;\n        _7672 = _3835;\n        _7673 = _3835 * _3835;\n        float _3847 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7675 = _3847;\n        _7668 = 1.0 - (_3820 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3847, 0.0, 1.0), 5.0))));\n        _7666 = true;\n    }\n    vec3 _3866 = max(s.sheen_color, vec3(0.0));\n    float _3875 = max(_3866.x, max(_3866.y, _3866.z));\n    if (_3875 > 0.0)\n    {\n        float _3883 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7676 = true;\n        _7677 = _3866;\n        _7678 = _3883;\n        _7679 = _3883 * _3883;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3883;\n        float _3900 = fa_sheen_albedo(param, param_1);\n        _7681 = _3900;\n        _7680 = 1.0 - min(_3875 * _3900, 1.0);\n        _7666 = true;\n    }\n    _7669 = _7668 * _7680;\n    float _3919 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3919 != 0.0)\n    {\n        vec3 _3934 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3934;\n        if (dot(_3934, _3934) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3946 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3946.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3946.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3946.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3950 = t;\n        vec3 _3951 = normalize(_3950);\n        t = _3951;\n        vec3 _3976 = normalize((_3951 * cos(s.anisotropy_rotation)) + ((cross(n, _3951) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7683 = _3976;\n        _7684 = cross(n, _3976);\n        float _3986 = roughness * roughness;\n        float _3992 = mix(_3986, 1.0, _3919 * _3919);\n        bool _3994 = _3919 > 0.0;\n        _7685 = _3994 ? _3992 : _3986;\n        _7686 = _3994 ? _3986 : _3992;\n        _7682 = _3919;\n        _7666 = true;\n    }\n    return FaLayers(_7666, _7667, _7668, _7669, _7670, _7671, _7672, _7673, i.world_normal, _7675, _7676, _7677, _7678, _7679, _7680, _7681, _7682, _7683, _7684, _7685, _7686);\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3375 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3375;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5123;\n    if (fa_lm.z > 0.5)\n    {\n        _5123 = 0.0;\n    }\n    else\n    {\n        _5123 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5134 = _5123 < 1.0;\n    bool _5140;\n    if (_5134)\n    {\n        int param = li;\n        _5140 = fa_light_baked(param);\n    }\n    else\n    {\n        _5140 = _5134;\n    }\n    return _5140 ? _5123 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _782 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _795 = (c - (ru * hx)) - p;\n        vec3 _801 = ru * (2.0 * hx);\n        float _807 = max(dot(_801, _801), 9.9999999392252902907785028219223e-09);\n        float _811 = dot(_795, _801);\n        float t = clamp((-_811) / _807, 0.0, 1.0);\n        if (_782)\n        {\n            float _826 = dot(r, _801);\n            float _832 = _807 - (_826 * _826);\n            if (abs(_832) > (9.9999997473787516355514526367188e-06 * _807))\n            {\n                t = clamp(((dot(r, _795) * _826) - _811) / _832, 0.0, 1.0);\n            }\n        }\n        return (p + _795) + (_801 * t);\n    }\n    vec3 q = p;\n    float _864 = dot(r, axis);\n    bool _872;\n    if (_782)\n    {\n        _872 = abs(_864) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _872 = _782;\n    }\n    if (_872)\n    {\n        float _882 = dot(c - p, axis) / _864;\n        if (_882 > 0.0)\n        {\n            q = p + (r * _882);\n        }\n    }\n    vec3 _895 = q - c;\n    vec2 xy = vec2(dot(_895, ru), dot(_895, uu));\n    if (shape > 0.5)\n    {\n        float _910 = length(xy);\n        if (_910 > hx)\n        {\n            xy *= (hx / _910);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _543 = abs(d);\n    float _545 = _543.x;\n    float _547 = _543.y;\n    bool _548 = _545 >= _547;\n    bool _556;\n    if (_548)\n    {\n        _556 = _545 >= _543.z;\n    }\n    else\n    {\n        _556 = _548;\n    }\n    int _557;\n    if (_556)\n    {\n        _557 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _572;\n        if (_547 >= _543.z)\n        {\n            _572 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _572 = (d.z > 0.0) ? 4 : 5;\n        }\n        _557 = _572;\n    }\n    return _557;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _702 = dot(d, right);\n    float _706 = dot(d, up);\n    float _717;\n    if (((_702 * _702) + (_706 * _706)) > 1.0000000133514319600180897396058e-10)\n    {\n        _717 = atan(_706, _702) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _717 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_717 - floor(_717)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _948 = fa_light_base(param);\n    bool _952 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _948;\n    vec4 _956 = fa_light_texel(param_1);\n    int param_2 = _948 + 1;\n    vec4 _961 = fa_light_texel(param_2);\n    float _964 = _961.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _976 = _952 && (_964 > 2.5);\n    fa_light_is_area = _976;\n    bool _978 = _964 < 0.5;\n    vec3 l;\n    if (_978)\n    {\n        l = normalize(_956.xyz);\n        if (_952)\n        {\n            int param_3 = _948 + 6;\n            vec4 _992 = fa_light_texel(param_3);\n            if (_992.z > 0.5)\n            {\n                int param_4 = _948 + 4;\n                vec4 _1002 = fa_light_texel(param_4);\n                int param_5 = _948 + 5;\n                vec4 _1007 = fa_light_texel(param_5);\n                vec2 param_6 = _992.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1002.xyz) * _1002.w, (-dot(world_pos, _1007.xyz)) * _1007.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1037 = _956.xyz;\n        vec3 _1039 = _1037 - world_pos;\n        vec3 to_light = _1039;\n        float _1042 = length(_1039);\n        float reach = _1042;\n        bool front = true;\n        if (_976)\n        {\n            int param_8 = _948 + 7;\n            reach = max(_1042 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _948 + 4;\n            vec4 _1066 = fa_light_texel(param_9);\n            int param_10 = _948 + 5;\n            vec4 _1071 = fa_light_texel(param_10);\n            int param_11 = _948 + 6;\n            vec4 _1076 = fa_light_texel(param_11);\n            float _1077 = _1076.w;\n            int param_12 = _948 + 2;\n            vec3 _1084 = normalize(fa_light_texel(param_12).xyz);\n            bool _1086 = _1077 > 1.5;\n            bool _1094;\n            if (!_1086)\n            {\n                _1094 = dot(_1084, to_light) < 0.0;\n            }\n            else\n            {\n                _1094 = _1086;\n            }\n            front = _1094;\n            vec3 r = vec3(0.0);\n            vec3 _1103 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1107 = dot(n, n) > 0.5;\n            bool _1115;\n            if (_1107)\n            {\n                _1115 = dot(_1103, _1103) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1115 = _1107;\n            }\n            if (_1115)\n            {\n                r = reflect(-normalize(_1103), normalize(n));\n            }\n            vec3 param_13 = _1037;\n            vec3 param_14 = _1084;\n            vec3 param_15 = _1066.xyz;\n            vec3 param_16 = _1071.xyz;\n            float param_17 = _1066.w;\n            float param_18 = _1071.w;\n            float param_19 = _1077;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1151 = length(to_light);\n        dist = _1151;\n        l = to_light / vec3(max(_1151, 9.9999997473787516355514526367188e-05));\n        float _1165 = reach / max(_956.w, 0.001000000047497451305389404296875);\n        float _1171 = clamp(1.0 - (_1165 * _1165), 0.0, 1.0);\n        float _1173;\n        if (front)\n        {\n            _1173 = _1171 * _1171;\n        }\n        else\n        {\n            _1173 = 0.0;\n        }\n        atten = _1173;\n        bool _1184 = _964 < 2.5;\n        if ((_964 > 1.5) && _1184)\n        {\n            int param_22 = _948 + 2;\n            vec4 _1192 = fa_light_texel(param_22);\n            float _1202 = _1192.w;\n            int param_23 = _948 + 3;\n            vec4 _1207 = fa_light_texel(param_23);\n            float _1208 = _1207.x;\n            float cos_inner = _1208;\n            if (_1208 > 1.5)\n            {\n                cos_inner = mix(_1202, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1202, cos_inner, dot(-l, normalize(_1192.xyz)));\n        }\n        if (_952 && (_964 < 1.5))\n        {\n            int param_24 = _948 + 6;\n            vec4 _1232 = fa_light_texel(param_24);\n            if (_1232.z > 0.5)\n            {\n                vec3 _1240 = -to_light;\n                int param_25 = _948 + 4;\n                int param_26 = _948 + 5;\n                vec3 _1254 = fa_light_texel(param_25).xyz;\n                vec3 _1258 = fa_light_texel(param_26).xyz;\n                vec3 _1267 = vec3(dot(_1240, _1254), dot(_1240, _1258), dot(_1240, cross(_1254, _1258)));\n                vec3 param_27 = _1267;\n                int _1271 = fa_cube_face(param_27);\n                int param_28 = _1271;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1298 = vec2(dot(_1267, cross(param_29, param_30)), dot(_1267, param_30)) / vec2(max(dot(_1267, param_29), 9.9999997473787516355514526367188e-05));\n                int _1302 = _1271 / 3;\n                vec2 param_31 = _1232.xy + (vec2(float(_1271 - (_1302 * 3)), float(_1302)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1298.x), 0.5 - (0.5 * _1298.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _948 + 7;\n            vec4 _1332 = fa_light_texel(param_33);\n            if (_1332.z > 0.5)\n            {\n                int param_34 = _948 + 2;\n                int param_35 = _948 + 4;\n                int param_36 = _948 + 5;\n                vec2 param_37 = _1332.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_952 && _1184)\n            {\n                int param_42 = _948 + 6;\n                vec4 _1379 = fa_light_texel(param_42);\n                int param_43 = _948 + 7;\n                vec4 _1384 = fa_light_texel(param_43);\n                bool _1387 = _1379.z > 0.5;\n                bool _1394;\n                if (!_1387)\n                {\n                    _1394 = _1384.z > 0.5;\n                }\n                else\n                {\n                    _1394 = _1387;\n                }\n                if (_1394)\n                {\n                    int param_44 = _948 + 2;\n                    vec4 _1401 = fa_light_texel(param_44);\n                    vec3 _1405 = normalize(_1401.xyz);\n                    int param_45 = _948 + 4;\n                    vec4 _1410 = fa_light_texel(param_45);\n                    int param_46 = _948 + 5;\n                    vec4 _1415 = fa_light_texel(param_46);\n                    if (_1387)\n                    {\n                        vec3 _1423 = -to_light;\n                        float _1430 = _1401.w;\n                        float _1446 = 0.5 / max(dot(_1423, _1405) * (sqrt(max(1.0 - (_1430 * _1430), 0.0)) / max(_1430, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1379.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1423, _1410.xyz) * _1446), 0.5 - (dot(_1423, _1415.xyz) * _1446));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1384.z > 0.5)\n                    {\n                        vec2 param_49 = _1384.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1405;\n                        vec3 param_52 = _1410.xyz;\n                        vec3 param_53 = _1415.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7654 = _961.xyz * atten;\n    if (_952)\n    {\n        _7654 *= fa_light_tint;\n    }\n    int _1515;\n    if (_978)\n    {\n        _1515 = 0;\n    }\n    else\n    {\n        _1515 = ((_964 > 1.5) && (_964 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7654, atten, 1.0, dist, _1515);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2252;\n    if (i == 0)\n    {\n        _2252 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2268;\n        if (i == 1)\n        {\n            _2268 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2276;\n            if (i == 2)\n            {\n                _2276 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2276 = fa_shadows[24].w;\n            }\n            _2268 = _2276;\n        }\n        _2252 = _2268;\n    }\n    return _2252;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2309 = fa_shadow_depth(param, param_1);\n    float _2313;\n    if (conv.x < 0.5)\n    {\n        _2313 = _2309;\n    }\n    else\n    {\n        _2313 = (conv.y * conv.z) / (conv.z - (_2309 * (conv.z - conv.y)));\n    }\n    return _2313;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2240 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2240), sin(_2240)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2359 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2368;\n        if (k < 0.0)\n        {\n            _2368 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2368 = k;\n        }\n        float _2388 = clamp((_2368 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2359;\n            vec2 _2407 = fa_shadow_vogel(param_3, param_4, param_5) * _2388;\n            vec2 param_6 = uv + (_2407 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2419 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2419 < (zr - (length(_2407) * plane)))\n            {\n                sum += _2419;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2445 = sum / cnt;\n        float _2455;\n        if (k < 0.0)\n        {\n            _2455 = (-k) / max(_2445, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2455 = k;\n        }\n        radius = clamp(((max(zr - _2445, 0.0) * unit) * _2455) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2477 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2477; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2477;\n        float param_11 = _2359;\n        vec2 _2496 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2496 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2496) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2477);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2538 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2543 = clamp(dot(n, l), 0.0, 1.0);\n    float _2549 = sqrt(1.0 - (_2543 * _2543));\n    float _2556 = min(_2549 / max(_2543, 0.20000000298023223876953125), 4.0);\n    float _2561;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2561 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2561 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2586 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2561 * _2549)), 1.0);\n    float _2593 = _2586.x;\n    bool _2596 = _2593 < fa_shadows[ci * 1 + 16].x;\n    bool _2605;\n    if (!_2596)\n    {\n        _2605 = _2593 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2605 = _2596;\n    }\n    bool _2614;\n    if (!_2605)\n    {\n        _2614 = _2586.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2614 = _2605;\n    }\n    bool _2623;\n    if (!_2614)\n    {\n        _2623 = _2586.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2623 = _2614;\n    }\n    bool _2630;\n    if (!_2623)\n    {\n        _2630 = _2586.z > 1.0;\n    }\n    else\n    {\n        _2630 = _2623;\n    }\n    if (_2630)\n    {\n        return -1.0;\n    }\n    float _2638;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2638 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2638 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2586.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2586.z - ((_2638 * (1.0 + (0.5 * _2556))) / _2538);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2538;\n    float param_5 = _2538 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2556, 3.0)) * 0.5) / _2538;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3016 = int(fa_shadows[25].x + 0.5);\n    if (_3016 < 1)\n    {\n        return 1.0;\n    }\n    float _3031 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3016 - 1;\n    if (_3031 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3043 = _3016 > 1;\n    bool _3050;\n    if (_3043)\n    {\n        _3050 = _3031 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3050 = _3043;\n    }\n    if (_3050)\n    {\n        ci = 1;\n    }\n    bool _3054 = _3016 > 2;\n    bool _3061;\n    if (_3054)\n    {\n        _3061 = _3031 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3061 = _3054;\n    }\n    if (_3061)\n    {\n        ci = 2;\n    }\n    bool _3065 = _3016 > 3;\n    bool _3072;\n    if (_3065)\n    {\n        _3072 = _3031 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3072 = _3065;\n    }\n    if (_3072)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3016)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3098 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3098;\n        if (_3098 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3123;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3123 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3123 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3142 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3123, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3153 = clamp((_3031 - (fa_shadow_split_at(param_7) - _3142)) / _3142, 0.0, 1.0);\n        if (_3153 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3016)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3174 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3174;\n                if (_3174 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3153);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2696 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2703;\n    if (!_2696)\n    {\n        _2703 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2703 = _2696;\n    }\n    if (_2703)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2716 = fa_light_texel(param);\n    float _2717 = _2716.x;\n    if (_2717 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2726 = int(_2717 + 0.5);\n    int param_1 = _2726;\n    vec4 _2730 = fa_light_texel(param_1);\n    int param_2 = _2726 + 1;\n    vec4 _2735 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2738 = _2730.y;\n    if (_2738 > 0.0)\n    {\n        float _2755 = 1.0 - smoothstep(0.75 * _2738, _2738, length(world - fa_shadows[27].xyz));\n        fade = _2755;\n        if (_2755 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2730.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2779 = (_2726 + 2) + (face * 6);\n    int param_4 = _2779;\n    int param_5 = _2779 + 1;\n    int param_6 = _2779 + 3;\n    vec4 _2793 = fa_light_texel(param_6);\n    int param_7 = _2779 + 4;\n    vec4 _2798 = fa_light_texel(param_7);\n    int param_8 = _2779 + 5;\n    vec4 _2803 = fa_light_texel(param_8);\n    float _2815 = _2803.x * max(dot(_2793, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2820 = clamp(dot(n, l), 0.0, 1.0);\n    float _2843 = clamp(dot(n, _2793.xyz), -1.0, 1.0);\n    float _2862 = min(sqrt(1.0 - (_2843 * _2843)) / max(abs(dot(n, world - lpos)) / max(dot(_2793, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2865 = _2735.y;\n    float _2867;\n    if (_2865 > 0.0)\n    {\n        _2867 = _2865;\n    }\n    else\n    {\n        _2867 = 1.5 * _2815;\n    }\n    vec4 _2887 = vec4(world + (n * (_2867 * sqrt(1.0 - (_2820 * _2820)))), 1.0);\n    float _2891 = dot(_2793, _2887);\n    float _2894 = _2803.y;\n    if (_2891 < _2894)\n    {\n        return 1.0;\n    }\n    vec2 _2909 = vec2(dot(fa_light_texel(param_4), _2887), dot(fa_light_texel(param_5), _2887)) / vec2(_2891);\n    float _2911 = _2909.x;\n    bool _2914 = _2911 < _2798.x;\n    bool _2923;\n    if (!_2914)\n    {\n        _2923 = _2911 > _2798.z;\n    }\n    else\n    {\n        _2923 = _2914;\n    }\n    bool _2932;\n    if (!_2923)\n    {\n        _2932 = _2909.y < _2798.y;\n    }\n    else\n    {\n        _2932 = _2923;\n    }\n    bool _2941;\n    if (!_2932)\n    {\n        _2941 = _2909.y > _2798.w;\n    }\n    else\n    {\n        _2941 = _2932;\n    }\n    if (_2941)\n    {\n        return 1.0;\n    }\n    float _2947 = _2735.x;\n    float _2949;\n    if (_2947 > 0.0)\n    {\n        _2949 = _2947;\n    }\n    else\n    {\n        _2949 = 1.5 * _2815;\n    }\n    vec2 param_9 = _2909;\n    vec4 param_10 = _2798;\n    float param_11 = _2891 - (_2949 * (1.0 + (0.5 * _2862)));\n    float param_12 = _2815;\n    float param_13 = 1.0;\n    float param_14 = _2803.z * 0.25;\n    float param_15 = (_2815 * min(_2862, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2894, _2803.z);\n    int param_17 = int(_2730.z + 0.5);\n    float param_18 = _2730.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4504 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4511;\n    if (!_4504)\n    {\n        _4511 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4511 = _4504;\n    }\n    if (_4511)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4524 = fa_light_texel(param);\n    float _4525 = _4524.y;\n    float len = _4525;\n    if (_4525 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4537 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4547 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4537);\n    if (_4547 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4553 = len;\n    float _4556 = min(_4553, 0.89999997615814208984375 * dist);\n    len = _4556;\n    float _4561 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4537);\n    float _4566 = _4561 + (0.5 * _4556);\n    vec3 _4572 = world + (gn * _4561);\n    float _4574 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4638;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4589 = (float(k) + _4574) * 0.083333335816860198974609375;\n        vec3 _4597 = _4572 + (l * (_4589 * len));\n        vec4 _4603 = vec4(_4597, 1.0);\n        float _4609 = dot(fa_mesh_fs_params[28], _4603);\n        if (_4609 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4629 = vec2(dot(fa_mesh_fs_params[26], _4603), dot(fa_mesh_fs_params[27], _4603)) / vec2(_4609);\n        float _4633 = _4629.x * 0.5;\n        float _4634 = _4633 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4638 = (_4629.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4638 = 0.5 - (_4629.y * 0.5);\n        }\n        bool _4654 = _4634 < 0.0;\n        bool _4661;\n        if (!_4654)\n        {\n            _4661 = _4634 >= 1.0;\n        }\n        else\n        {\n            _4661 = _4654;\n        }\n        bool _4668;\n        if (!_4661)\n        {\n            _4668 = _4638 < 0.0;\n        }\n        else\n        {\n            _4668 = _4661;\n        }\n        bool _4675;\n        if (!_4668)\n        {\n            _4675 = _4638 >= 1.0;\n        }\n        else\n        {\n            _4675 = _4668;\n        }\n        if (_4675)\n        {\n            break;\n        }\n        vec4 _4694 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4634, _4638) * fa_mesh_fs_params[24].zw), 0);\n        if (_4694.w < 0.5)\n        {\n            continue;\n        }\n        float _4713 = (dot(fa_mesh_fs_params[29].xyz, _4597) + fa_mesh_fs_params[29].w) - _4694.x;\n        if ((_4713 > _4561) && (_4713 < _4566))\n        {\n            occ = max(occ, (1.0 - (_4589 * _4589)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4634, 0.5 - _4633), min(_4638, 1.0 - _4638))));\n        }\n    }\n    return 1.0 - (occ * _4547);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5179 = fa_baked_keep(param);\n    if (_5179 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5205 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7723 = _5205.color;\n    float _7724 = _5205.attenuation;\n    float _7725 = _5205.shadow;\n    bool _5208 = _5205.type == 0;\n    if (_5208 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5205.direction;\n        float _5219 = fa_shadow_factor(param_5, param_6);\n        _7725 = _5219;\n        _7723 *= _5219;\n    }\n    else\n    {\n        bool _5230 = _5205.type != 0;\n        bool _5236;\n        if (_5230)\n        {\n            _5236 = _7724 > 0.0;\n        }\n        else\n        {\n            _5236 = _5230;\n        }\n        if (_5236)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5205.direction;\n            float _5255 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7725 = _5255;\n            _7723 *= _5255;\n        }\n    }\n    bool _5265 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5271;\n    if (_5265)\n    {\n        _5271 = _7724 > 0.0;\n    }\n    else\n    {\n        _5271 = _5265;\n    }\n    if (_5271)\n    {\n        float _5278;\n        if (_5208)\n        {\n            _5278 = 1000000000.0;\n        }\n        else\n        {\n            _5278 = _5205._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5205.direction;\n        float param_18 = _5278;\n        float _5296 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7725 *= _5296;\n        _7723 *= _5296;\n    }\n    float _5309 = _7724;\n    float _5310 = _5309 * _5179;\n    _7724 = _5310;\n    vec3 _5314 = _7723;\n    vec3 _5315 = _5314 * _5179;\n    _7723 = _5315;\n    return LightSample(_5205.direction, _5315, _5310, _7725, _5205._distance, _5205.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5349 = v - (n * dot(v, n));\n    vec3 t = _5349;\n    float _5353 = dot(_5349, _5349);\n    float l2 = _5353;\n    if (_5353 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5363;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5363 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5363 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5363;\n        l2 = dot(_5363, _5363);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5398 = dot(a, a);\n    float _5402 = dot(b, b);\n    if ((_5398 < 1.0000000195414813782625560981111e-24) || (_5402 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5416 = a * inversesqrt(_5398);\n    vec3 _5421 = b * inversesqrt(_5402);\n    float _5425 = dot(_5416, _5421);\n    float _5428 = abs(_5425);\n    float g = (((((((((((0.0416471660137176513671875 * _5428) - 0.1924748718738555908203125) * _5428) + 0.4179156124591827392578125) * _5428) - 0.616057217121124267578125) * _5428) + 0.777722418308258056640625) * _5428) - 0.999542415142059326171875) * _5428) + 1.570791721343994140625;\n    if (_5425 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5425 * _5425), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5416, _5421) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5485 = a.z > 0.0;\n    bool _5489 = b.z > 0.0;\n    if (_5485 && _5489)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5485 != _5489)\n        {\n            vec3 _5524 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5524.z = 0.0;\n            if (_5485)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5524;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5524;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5524;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5524;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5573 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5599 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5625 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5651 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5573;\n    vec3 param_1 = _5599;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5599;\n    vec3 param_7 = _5625;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5625;\n    vec3 param_13 = _5651;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5651;\n    vec3 param_19 = _5573;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _5800 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5824 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _5840 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _5800;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _5824;\n    vec4 param_9 = m;\n    vec3 param_10 = _5800;\n    vec3 param_11 = _5824;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _5840;\n    vec4 param_14 = m;\n    vec3 param_15 = _5800;\n    vec3 param_16 = _5840;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _5898 = fa_light_base(param);\n    int param_1 = _5898;\n    int param_2 = _5898 + 1;\n    int param_3 = _5898 + 2;\n    int param_4 = _5898 + 4;\n    vec4 _5920 = fa_light_texel(param_4);\n    int param_5 = _5898 + 5;\n    vec4 _5925 = fa_light_texel(param_5);\n    int param_6 = _5898 + 6;\n    vec4 _5930 = fa_light_texel(param_6);\n    float _5931 = _5930.w;\n    vec3 _5936 = fa_light_texel(param_1).xyz - world_pos;\n    bool _5938 = _5931 < 1.5;\n    bool _5945;\n    if (_5938)\n    {\n        _5945 = dot(normalize(fa_light_texel(param_3).xyz), _5936) >= 0.0;\n    }\n    else\n    {\n        _5945 = _5938;\n    }\n    if (_5945)\n    {\n        return vec3(0.0);\n    }\n    bool _5954 = (_5931 > 0.5) && _5938;\n    float _5958 = _5954 ? 1.0539000034332275390625 : 1.0;\n    vec3 _5961 = _5920.xyz;\n    float _5963 = _5920.w;\n    vec3 _5969 = _5925.xyz;\n    float _5971 = _5925.w;\n    vec3 up = _5969 * (_5971 * _5958);\n    float _5977;\n    if (_5954)\n    {\n        _5977 = (3.1415927410125732421875 * _5963) * _5963;\n    }\n    else\n    {\n        _5977 = (4.0 * _5963) * _5971;\n    }\n    if (_5931 > 1.5)\n    {\n        vec3 _6003 = cross(_5961, -_5936);\n        vec3 perp = _6003;\n        float _6007 = dot(_6003, _6003);\n        vec3 _6010;\n        if (_6007 > 1.0000000133514319600180897396058e-10)\n        {\n            _6010 = perp * inversesqrt(_6007);\n        }\n        else\n        {\n            _6010 = _5969;\n        }\n        perp = _6010;\n        up = _6010 * _5971;\n    }\n    float _6031 = max(_5977, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6041 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6041;\n    vec3 param_10 = n;\n    vec3 param_11 = _5936;\n    vec3 _6049 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6041;\n    vec3 param_13 = n;\n    vec3 param_14 = _5961 * (_5963 * _5958);\n    vec3 _6057 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6041;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6065 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _5931;\n    vec3 param_20 = _6049;\n    vec3 param_21 = _6057;\n    vec3 param_22 = _6065;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6084 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6084;\n    vec2 param_26 = _6084 + vec2(64.0, 0.0);\n    vec4 _6094 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _5931;\n    vec3 param_29 = _6049;\n    vec3 param_30 = _6057;\n    vec3 param_31 = _6065;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6094.x) + ((vec3(f90) - f0) * _6094.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_5936, _5936)) + _6031) / _6031) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4241 = 1.0 / alpha;\n    return ((2.0 + _4241) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4241)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4276 = max(dot(L.nc, l), 0.0);\n    float _4282 = max(dot(L.nc, h), 0.0);\n    float _4291 = ((_4282 * _4282) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4291) * _4291)) * (0.5 / max(mix((2.0 * _4276) * L.coat_ndv, _4276 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4276)) * _4276;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6162;\n    if (L.sheen_on)\n    {\n        _6162 = L.sheen_scale;\n    }\n    else\n    {\n        _6162 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6162);\n    vec3 _6175 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6186 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6195 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6175), 0.0);\n        float param_13 = _6195;\n        float param_14 = ndv;\n        result += ((L.sheen * _6186) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6195)) * _6195) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6175;\n        float param_18 = max(dot(v, _6175), 0.0);\n        result += (_6186 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4144 = tdh / at;\n    float _4148 = bdh / ab;\n    float _4160 = ((_4144 * _4144) + (_4148 * _4148)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4160) * _4160);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4340 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _4419 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _4419) * _4419);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4340);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4340));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3550 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3553 = _3550.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3553 * _3553, exp2((-9.27999973297119140625) * ndv)) * _3553) + _3550.y)) + _3550.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3404 = rough * rough;\n    float _3434 = 0.60000002384185791015625 * _3404;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3404)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3434, 0.0500000007450580596923828125 + _3434, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3404 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4027;\n        if (L.aniso >= 0.0)\n        {\n            _4027 = L.b;\n        }\n        else\n        {\n            _4027 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4027, v), _4027), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4060 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4060.x) + (vec3(L.f90) * _4060.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4115 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4115.x) + _4115.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3592 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3592.x) + vec3(_3592.y));\n}\n\nvec2 fa_xm_size(int k)\n{\n    return max(floor(fa_mesh_fs_params[24].zw / vec2(exp2(float(k)))), vec2(1.0));\n}\n\nvec2 fa_xm_origin(int k)\n{\n    if (k == 0)\n    {\n        return vec2(0.0);\n    }\n    float y = 0.0;\n    for (int j = 1; j < k; j++)\n    {\n        int param = j;\n        y += fa_xm_size(param).y;\n    }\n    return vec2(fa_mesh_fs_params[24].z, y);\n}\n\nvec3 fa_xm_texel(vec2 size, vec2 origin, vec2 p)\n{\n    return texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(origin + clamp(p, vec2(0.0), size - vec2(1.0))), 0).xyz;\n}\n\nvec3 fa_xm_level(int k, vec2 uv)\n{\n    int param = k;\n    vec2 _4817 = fa_xm_size(param);\n    int param_1 = k;\n    vec2 _4821 = fa_xm_origin(param_1);\n    vec2 _4827 = (uv * _4817) - vec2(0.5);\n    vec2 _4830 = fract(_4827);\n    vec2 _4833 = floor(_4827);\n    vec2 param_2 = _4817;\n    vec2 param_3 = _4821;\n    vec2 param_4 = _4833;\n    vec2 param_5 = _4817;\n    vec2 param_6 = _4821;\n    vec2 param_7 = _4833 + vec2(1.0, 0.0);\n    vec2 param_8 = _4817;\n    vec2 param_9 = _4821;\n    vec2 param_10 = _4833 + vec2(0.0, 1.0);\n    vec2 param_11 = _4817;\n    vec2 param_12 = _4821;\n    vec2 param_13 = _4833 + vec2(1.0);\n    vec3 _4875 = vec3(_4830.x);\n    return mix(mix(fa_xm_texel(param_2, param_3, param_4), fa_xm_texel(param_5, param_6, param_7), _4875), mix(fa_xm_texel(param_8, param_9, param_10), fa_xm_texel(param_11, param_12, param_13), _4875), vec3(_4830.y));\n}\n\nvec3 fa_xm_sample(vec2 uv, float lod)\n{\n    float _4894 = max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    float _4898 = clamp(lod, 0.0, _4894);\n    int _4902 = int(floor(_4898));\n    int param = _4902;\n    vec2 param_1 = uv;\n    vec3 c = fa_xm_level(param, param_1);\n    float _4912 = float(_4902);\n    float _4913 = _4898 - _4912;\n    bool _4915 = _4913 > 0.001000000047497451305389404296875;\n    bool _4922;\n    if (_4915)\n    {\n        _4922 = _4912 < _4894;\n    }\n    else\n    {\n        _4922 = _4915;\n    }\n    if (_4922)\n    {\n        int param_2 = _4902 + 1;\n        vec2 param_3 = uv;\n        c = mix(c, fa_xm_level(param_2, param_3), vec3(_4913));\n    }\n    return c;\n}\n\nvec3 fa_transmitted(Surface s, vec3 n, vec3 v, float roughness, vec3 f0, float f90, float keep, float tr, inout float blend)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4948 = fa_env_brdf(param, param_1);\n    vec3 through = ((vec3(1.0) - clamp((f0 * _4948.x) + (vec3(f90) * _4948.y), vec3(0.0), vec3(1.0))) * s.albedo) * (tr * keep);\n    float _4976 = max(s.thickness, 0.0);\n    bool _4981 = _4976 > 0.0;\n    if ((s.attenuation_distance > 0.0) && _4981)\n    {\n        through *= exp((-((-log(clamp(s.attenuation_color, vec3(9.9999997473787516355514526367188e-05), vec3(1.0)))) / vec3(s.attenuation_distance))) * _4976);\n    }\n    bool _5006 = fa_mesh_fs_params[30].w > 1.5;\n    bool _5013;\n    if (!_5006)\n    {\n        _5013 = fa_mesh_fs_params[30].w < 0.5;\n    }\n    else\n    {\n        _5013 = _5006;\n    }\n    if (_5013)\n    {\n        blend = clamp(dot(through, vec3(0.3333333432674407958984375)), 0.0, 0.980000019073486328125);\n        return vec3(0.0);\n    }\n    vec3 world = fa_world_pos;\n    if (_4981)\n    {\n        world += (refract(-v, n, 1.0 / max(s.ior, 1.0)) * _4976);\n    }\n    vec4 _5048 = vec4(world, 1.0);\n    float _5053 = dot(fa_mesh_fs_params[28], _5048);\n    vec2 uv = vec2(0.5);\n    if (_5053 > 9.9999997473787516355514526367188e-05)\n    {\n        vec2 _5071 = vec2(dot(fa_mesh_fs_params[26], _5048), dot(fa_mesh_fs_params[27], _5048)) / vec2(_5053);\n        float _5079;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5079 = (_5071.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5079 = 0.5 - (_5071.y * 0.5);\n        }\n        uv = vec2((_5071.x * 0.5) + 0.5, _5079);\n    }\n    vec2 param_2 = clamp(uv, vec2(0.0), vec2(1.0));\n    float param_3 = (clamp(roughness, 0.0, 1.0) * clamp((2.0 * s.ior) - 2.0, 0.0, 1.0)) * max(fa_mesh_fs_params[31].w - 1.0, 0.0);\n    return through * fa_xm_sample(param_2, param_3);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3198 = int(fa_shadows[25].x + 0.5);\n    float _3208 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3213 = _3198 > 0;\n    bool _3222;\n    if (_3213)\n    {\n        int param = _3198 - 1;\n        _3222 = _3208 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3222 = _3213;\n    }\n    if (_3222)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3228 = _3198 > 1;\n        bool _3235;\n        if (_3228)\n        {\n            _3235 = _3208 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3235 = _3228;\n        }\n        if (_3235)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3241 = _3198 > 2;\n        bool _3248;\n        if (_3241)\n        {\n            _3248 = _3208 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3248 = _3241;\n        }\n        if (_3248)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3254 = _3198 > 3;\n        bool _3261;\n        if (_3254)\n        {\n            _3261 = _3208 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3261 = _3254;\n        }\n        if (_3261)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7382 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7382 = -_7382;\n    }\n    vec3 _6677 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7382, fa_world_tangent, fa_uv, fa_vertex_color, _6677, gl_FrontFacing);\n    Surface _6685 = fa_standard_surface(param_1);\n    vec3 _7413 = _6685.albedo;\n    float _7414 = _6685.alpha;\n    vec3 _7415 = _6685.normal;\n    float _7416 = _6685.metallic;\n    float _7417 = _6685.roughness;\n    float _7418 = _6685.occlusion;\n    vec3 _7419 = _6685.emission;\n    float _7420 = _6685.clearcoat;\n    float _7421 = _6685.clearcoat_roughness;\n    vec3 _7422 = _6685.sheen_color;\n    float _7423 = _6685.sheen_roughness;\n    float _7424 = _6685.anisotropy;\n    float _7425 = _6685.anisotropy_rotation;\n    float _7426 = _6685.specular;\n    float _7427 = _6685.ior;\n    vec3 _7428 = _6685.specular_color;\n    float _7429 = _6685.transmission;\n    float _7430 = _6685.thickness;\n    vec3 _7431 = _6685.attenuation_color;\n    float _7432 = _6685.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7382, fa_world_tangent, fa_uv, fa_vertex_color, _6677, gl_FrontFacing);\n    Surface param_3 = _6685;\n    surface(param_2, param_3);\n    _7413 = param_3.albedo;\n    _7414 = param_3.alpha;\n    _7415 = param_3.normal;\n    _7416 = param_3.metallic;\n    _7417 = param_3.roughness;\n    _7418 = param_3.occlusion;\n    _7419 = param_3.emission;\n    _7420 = param_3.clearcoat;\n    _7421 = param_3.clearcoat_roughness;\n    _7422 = param_3.sheen_color;\n    _7423 = param_3.sheen_roughness;\n    _7424 = param_3.anisotropy;\n    _7425 = param_3.anisotropy_rotation;\n    _7426 = param_3.specular;\n    _7427 = param_3.ior;\n    _7428 = param_3.specular_color;\n    _7429 = param_3.transmission;\n    _7430 = param_3.thickness;\n    _7431 = param_3.attenuation_color;\n    _7432 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7382;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7413 = param_6;\n    _7415 = param_7;\n    float fa_tr_blend = 0.0;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7413;\n    }\n    else\n    {\n        vec3 _6725 = normalize(_7415);\n        float _6732 = clamp(_7416, 0.0, 1.0);\n        float _6736 = clamp(_7417, 0.0500000007450580596923828125, 1.0);\n        float _6740 = _6736 * _6736;\n        float _6744 = _6740 * _6740;\n        float _6749 = max(dot(_6725, _6677), 9.9999997473787516355514526367188e-05);\n        float _6755 = 1.0 - _6732;\n        float _6756 = clamp(_7429, 0.0, 1.0) * _6755;\n        vec3 _6765 = (_7413 * _6755) * (1.0 - _6756);\n        vec3 _6772 = mix(vec3(0.039999999105930328369140625), _7413, vec3(_6732));\n        vec3 f0 = _6772;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7382, fa_world_tangent, fa_uv, fa_vertex_color, _6677, gl_FrontFacing);\n        Surface param_9 = Surface(_7413, _7414, _7415, _7416, _7417, _7418, _7419, _7420, _7421, _7422, _7423, _7424, _7425, _7426, _7427, _7428, _7429, _7430, _7431, _7432);\n        vec3 param_10 = _6725;\n        vec3 param_11 = _6677;\n        float param_12 = _6732;\n        float param_13 = _6736;\n        vec3 param_14 = _6772;\n        FaLayers _6788 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6725;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6765) * _7418;\n        if (_6788.on)\n        {\n            lit *= _6788.base_scale;\n        }\n        int _6810 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6810; ln++)\n        {\n            int param_16 = ln;\n            int _6823 = fa_cl_light(param_16);\n            int param_17 = _6823;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _6823;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7382;\n            LightSample _6839 = fa_light_shadowed(param_18, param_19, param_20);\n            float _6847 = max(dot(_6725, _6839.direction), 0.0);\n            float _6853 = _6839.attenuation * _6839.shadow;\n            vec3 _6858 = normalize(_6839.direction + _6677);\n            float _6863 = max(dot(_6725, _6858), 0.0);\n            float _6868 = max(dot(_6677, _6858), 0.0);\n            bool _6875;\n            if (fa_light_is_area)\n            {\n                _6875 = !_6788.on;\n            }\n            else\n            {\n                _6875 = fa_light_is_area;\n            }\n            if (_6875)\n            {\n                int param_21 = _6823;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6725;\n                vec3 param_24 = _6677;\n                vec3 param_25 = _6765;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6736;\n                float param_29 = _6749;\n                float param_30 = _6853;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6788;\n                    int param_32 = _6823;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6725;\n                    vec3 param_35 = _6677;\n                    vec3 param_36 = _6839.direction;\n                    vec3 param_37 = _6765;\n                    vec3 param_38 = f0;\n                    float param_39 = _6736;\n                    float param_40 = _6749;\n                    float param_41 = _6853;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6788.on)\n                    {\n                        FaLayers param_42 = _6788;\n                        vec3 param_43 = _6765;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6725;\n                        vec3 param_46 = _6677;\n                        vec3 param_47 = _6839.direction;\n                        vec3 param_48 = _6858;\n                        float param_49 = _6847;\n                        float param_50 = _6749;\n                        float param_51 = _6863;\n                        float param_52 = _6868;\n                        float param_53 = _6740;\n                        float param_54 = _6744;\n                        int param_55 = _6823;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _6853));\n                    }\n                    else\n                    {\n                        float _6981 = ((_6863 * _6863) * (_6744 - 1.0)) + 1.0;\n                        int param_56 = _6823;\n                        lit += (((_6765 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _6868, 5.0))) * (((_6744 / ((3.1415927410125732421875 * _6981) * _6981)) * (0.5 / max(mix((2.0 * _6847) * _6749, _6847 + _6749, _6740), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _6847))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_6847 * _6853));\n                    }\n                }\n            }\n        }\n        if (_6788.on)\n        {\n            FaLayers param_57 = _6788;\n            vec3 param_58 = _6725;\n            vec3 param_59 = _6677;\n            vec3 param_60 = f0;\n            float param_61 = _6736;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7418);\n        }\n        else\n        {\n            vec3 param_62 = _6725;\n            vec3 param_63 = _6677;\n            vec3 param_64 = f0;\n            float param_65 = _6736;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7418);\n        }\n        if (_6756 > 0.0)\n        {\n            float _7079;\n            if (_6788.on)\n            {\n                _7079 = _6788.f90;\n            }\n            else\n            {\n                _7079 = 1.0;\n            }\n            float _7087;\n            if (_6788.on)\n            {\n                _7087 = _6788.base_scale;\n            }\n            else\n            {\n                _7087 = 1.0;\n            }\n            Surface param_66 = Surface(_7413, _7414, _7415, _7416, _7417, _7418, _7419, _7420, _7421, _7422, _7423, _7424, _7425, _7426, _7427, _7428, _7429, _7430, _7431, _7432);\n            vec3 param_67 = _6725;\n            vec3 param_68 = _6677;\n            float param_69 = _6736;\n            vec3 param_70 = f0;\n            float param_71 = _7079;\n            float param_72 = _7087;\n            float param_73 = _6756;\n            float param_74 = fa_tr_blend;\n            vec3 _7111 = fa_transmitted(param_66, param_67, param_68, param_69, param_70, param_71, param_72, param_73, param_74);\n            fa_tr_blend = param_74;\n            lit += _7111;\n        }\n        result = lit;\n    }\n    vec3 _7118 = result;\n    vec3 _7119 = _7118 + _7419;\n    result = _7119;\n    vec3 param_75 = _7119;\n    vec3 param_76 = fa_world_pos;\n    result = fa_shadow_debug(param_75, param_76);\n    bool _7128 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7135;\n    if (!_7128)\n    {\n        _7135 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7135 = _7128;\n    }\n    if (_7135)\n    {\n        vec3 _7144 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7150 = dot(_7144, fa_mesh_fs_params[9].xyz);\n        bool _7154 = fa_mesh_fs_params[9].w > 0.5;\n        float _7155;\n        if (_7154)\n        {\n            _7155 = _7150;\n        }\n        else\n        {\n            _7155 = length(_7144);\n        }\n        float _7167 = _7155 - fa_mesh_fs_params[8].x;\n        if (_7167 > 0.0)\n        {\n            float _7176 = fa_mesh_fs_params[7].w * _7167;\n            float tau = _7176 * _7176;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7192;\n                if (_7154)\n                {\n                    _7192 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7150);\n                }\n                else\n                {\n                    _7192 = fa_mesh_fs_params[0].y;\n                }\n                float _7213 = mix(_7192, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7155, 0.0, 1.0));\n                float _7217 = fa_world_pos.y - _7213;\n                float _7222 = _7213 - fa_mesh_fs_params[8].z;\n                float _7227 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7230 = _7222 <= 0.0;\n                bool _7231 = !_7230;\n                bool _7237;\n                if (_7231)\n                {\n                    _7237 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7237 = _7230;\n                }\n                float _7238;\n                if (_7237)\n                {\n                    _7238 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7238 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7222, 80.0));\n                }\n                bool _7265;\n                if (_7231)\n                {\n                    _7265 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7265 = _7230;\n                }\n                float _7266;\n                if (_7265)\n                {\n                    _7266 = fa_mesh_fs_params[8].y * _7222;\n                }\n                else\n                {\n                    _7266 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7222, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7291 = _7227 <= 0.0;\n                bool _7298;\n                if (!_7291)\n                {\n                    _7298 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7298 = _7291;\n                }\n                float _7299;\n                if (_7298)\n                {\n                    _7299 = fa_mesh_fs_params[8].y * _7227;\n                }\n                else\n                {\n                    _7299 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7227, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7326;\n                if (abs(_7217) < 0.001000000047497451305389404296875)\n                {\n                    _7326 = _7238;\n                }\n                else\n                {\n                    _7326 = (_7299 - _7266) / _7217;\n                }\n                tau += (_7167 * max(_7326, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    if (fa_tr_blend > 0.0)\n    {\n        float _7362 = 1.0 - fa_tr_blend;\n        result /= vec3(_7362);\n        _7414 *= _7362;\n    }\n    fa_frag_color = vec4(result, _7414);\n}\n\n",
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
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_attr_uv1"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_attr_color1"
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
            "inst_name": "_195",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_595",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
            "inst_name": "_2262",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) in vec2 fa_attr_uv1;\nlayout(location = 10) in vec4 fa_attr_color1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 vertex_color1;\nvec2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _180 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _187 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_180 * _187).z;\n    fa_pre_r0 = vec3(_180[0].x, _180[1].x, _180[2].x);\n    fa_pre_r1 = vec3(_180[0].y, _180[1].y, _180[2].y);\n    fa_pre_r2 = vec3(_180[0].z, _180[1].z, _180[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _187;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[41];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _240 = fa_tex_fix(param_2, param_3);\n    vec4 _791 = base_t;\n    _791.x = _240.x;\n    _791.y = _240.y;\n    _791.z = _240.z;\n    base_t = _791;\n    vec4 _255 = (_791 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _289 = fa_tex_fix(param_6, param_7);\n        vec3 _292 = (_289 * 2.0) - vec3(1.0);\n        vec2 _297 = _292.xy * fa_mesh_fs_params[6].x;\n        vec3 _799 = _292;\n        _799.x = _297.x;\n        _799.y = _297.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _799;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _326 = fa_tex_fix(param_12, param_13);\n    vec4 _802 = mrt;\n    _802.x = _326.x;\n    _802.y = _326.y;\n    _802.z = _326.z;\n    mrt = _802;\n    vec4 _356 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[20].x;\n    float _752 = fa_mesh_fs_params[20].y;\n    float _755 = fa_mesh_fs_params[20].z;\n    float _754 = fa_mesh_fs_params[21].w;\n    float _757 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _751 *= _368.y;\n            _752 *= _368.z;\n            _754 *= _356.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_255.xyz, _255.w, _746, clamp(fa_mesh_fs_params[5].x * _326.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_368.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _751, _752, fa_mesh_fs_params[21].xyz, _754, _755, fa_mesh_fs_params[20].w, _757, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _641 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _641 = -_641;\n    }\n    vec3 _551 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _566 = normalize(param_2.normal);\n    vec3 _581 = normalize(vec3(dot(fa_pre_r0, _566), dot(fa_pre_r1, _566), dot(fa_pre_r2, _566)));\n    float _593 = _581.z;\n    vec2 e = _581.xy / vec2((abs(_581.x) + abs(_581.y)) + abs(_593));\n    if (_593 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_attr_uv1"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_attr_color1"
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
          },
          {
            "slot": 1,
            "stage": "fragment",
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_228",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 11) in vec2 fa_attr_uv1;\nlayout(location = 12) in vec4 fa_attr_color1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 vertex_color1;\nvec2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_186 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_186 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_186 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _293 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _300 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_293 * _300).z;\n    fa_pre_r0 = vec3(_293[0].x, _293[1].x, _293[2].x);\n    fa_pre_r1 = vec3(_293[0].y, _293[1].y, _293[2].y);\n    fa_pre_r2 = vec3(_293[0].z, _293[1].z, _293[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _300;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[41];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _240 = fa_tex_fix(param_2, param_3);\n    vec4 _791 = base_t;\n    _791.x = _240.x;\n    _791.y = _240.y;\n    _791.z = _240.z;\n    base_t = _791;\n    vec4 _255 = (_791 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _746 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _289 = fa_tex_fix(param_6, param_7);\n        vec3 _292 = (_289 * 2.0) - vec3(1.0);\n        vec2 _297 = _292.xy * fa_mesh_fs_params[6].x;\n        vec3 _799 = _292;\n        _799.x = _297.x;\n        _799.y = _297.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _799;\n        _746 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _326 = fa_tex_fix(param_12, param_13);\n    vec4 _802 = mrt;\n    _802.x = _326.x;\n    _802.y = _326.y;\n    _802.z = _326.z;\n    mrt = _802;\n    vec4 _356 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _751 = fa_mesh_fs_params[20].x;\n    float _752 = fa_mesh_fs_params[20].y;\n    float _755 = fa_mesh_fs_params[20].z;\n    float _754 = fa_mesh_fs_params[21].w;\n    float _757 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _751 *= _368.y;\n            _752 *= _368.z;\n            _754 *= _356.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _755 *= mrt.x;\n            _757 *= mrt.w;\n        }\n    }\n    return Surface(_255.xyz, _255.w, _746, clamp(fa_mesh_fs_params[5].x * _326.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_368.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _751, _752, fa_mesh_fs_params[21].xyz, _754, _755, fa_mesh_fs_params[20].w, _757, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _641 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _641 = -_641;\n    }\n    vec3 _551 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _641, fa_world_tangent, fa_uv, fa_vertex_color, _551, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _566 = normalize(param_2.normal);\n    vec3 _581 = normalize(vec3(dot(fa_pre_r0, _566), dot(fa_pre_r1, _566), dot(fa_pre_r2, _566)));\n    float _593 = _581.z;\n    vec2 e = _581.xy / vec2((abs(_581.x) + abs(_581.y)) + abs(_593));\n    if (_593 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_attr_uv1"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_attr_color1"
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
            "inst_name": "_195",
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
            "size": 656,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_228",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 41,
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 9) in vec2 fa_attr_uv1;\nlayout(location = 10) in vec4 fa_attr_color1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 5) in vec3 fa_normal;\nlayout(location = 7) in vec4 fa_tangent;\nlayout(location = 6) in vec2 fa_texcoord0;\nlayout(location = 8) in vec4 fa_color;\nvec4 vertex_color1;\nvec2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_6.world_pos, 1.0);\n}\n\n",
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
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_attr_uv1"
          },
          {
            "slot": 10,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_attr_color1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_135",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 11) in vec2 fa_attr_uv1;\nlayout(location = 12) in vec4 fa_attr_color1;\nlayout(location = 1) in vec4 fa_inst_m0;\nlayout(location = 2) in vec4 fa_inst_m1;\nlayout(location = 3) in vec4 fa_inst_m2;\nlayout(location = 4) in vec4 fa_inst_m3;\nlayout(location = 5) in vec4 fa_joints;\nlayout(location = 6) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 7) in vec3 fa_normal;\nlayout(location = 9) in vec4 fa_tangent;\nlayout(location = 8) in vec2 fa_texcoord0;\nlayout(location = 10) in vec4 fa_color;\nvec4 vertex_color1;\nvec2 vertex_uv1;\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _177 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_177 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_177 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_177 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _79 = cross(model[1].xyz, model[2].xyz);\n    float _85 = (dot(model[0].xyz, _79) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_79 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _85, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _85), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid main()\n{\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    fa_inst_begin();\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    VertexData param_8 = fa_vertex_data(param_2, param_3, param_4, param_5, param_6, param_7);\n    vertex(param_8);\n    gl_Position = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]) * vec4(param_8.world_pos, 1.0);\n}\n\n",
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
            "type": "vec2",
            "base_type": "Float",
            "glsl_name": "fa_attr_uv1"
          },
          {
            "slot": 12,
            "type": "vec4",
            "base_type": "Float",
            "glsl_name": "fa_attr_color1"
          }
        ],
        "uniform_blocks": [
          {
            "slot": 0,
            "stage": "vertex",
            "size": 176,
            "struct_name": "fa_mesh_vs_params",
            "inst_name": "_140",
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
            "inst_name": "_186",
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
