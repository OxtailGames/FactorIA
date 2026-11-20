{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "57cbd5df71b0000e548dcd5fbfe873bc15510a64a336f6248792368f21adbf33",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4285[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1540 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1547;\n    if (!_1540)\n    {\n        _1547 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1547 = _1540;\n    }\n    bool _1555;\n    if (!_1547)\n    {\n        _1555 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1555 = _1547;\n    }\n    bool _1562;\n    if (!_1555)\n    {\n        _1562 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1562 = _1555;\n    }\n    bool _1569;\n    if (!_1562)\n    {\n        _1569 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1569 = _1562;\n    }\n    if (_1569)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1579 = vec4(world_pos, 1.0);\n    float _1585 = dot(fa_mesh_fs_params[16], _1579);\n    if (!(_1585 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1607 = vec2(dot(fa_mesh_fs_params[14], _1579), dot(fa_mesh_fs_params[15], _1579)) / vec2(_1585);\n    int _1611 = int(fa_mesh_fs_params[18].x);\n    int _1615 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1615) + clamp(int(floor(((_1607.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1615 - 1)) * _1611)) + clamp(int(floor(((_1607.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1611 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1691 = fa_cluster_texel(param);\n    return ivec2(int(_1691.x), int(_1691.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5383 = fa_cluster_lookup(param);\n    fa_cl_slot = _5383.x;\n    fa_cl_local = _5383.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6528 = fa_linear_to_srgb(param);\n        c = _6528;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6536 = fa_srgb_to_linear(param_1);\n            c = _6536;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _484;\n    if (i.front_facing)\n    {\n        _484 = i.world_normal;\n    }\n    else\n    {\n        _484 = -i.world_normal;\n    }\n    vec3 _508 = normalize(i.world_tangent.xyz - (_484 * dot(_484, i.world_tangent.xyz)));\n    vec3 _535 = normalize(((_508 * m.x) + ((cross(_484, _508) * i.world_tangent.w) * m.y)) + (_484 * m.z));\n    vec3 _538;\n    if (i.front_facing)\n    {\n        _538 = _535;\n    }\n    else\n    {\n        _538 = -_535;\n    }\n    return _538;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6567 = fa_tex_fix(param_2, param_3);\n    vec4 _8052 = base_t;\n    _8052.x = _6567.x;\n    _8052.y = _6567.y;\n    _8052.z = _6567.z;\n    base_t = _8052;\n    vec4 _6581 = (_8052 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7852 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6613 = fa_tex_fix(param_6, param_7);\n        vec3 _6616 = (_6613 * 2.0) - vec3(1.0);\n        vec2 _6621 = _6616.xy * fa_mesh_fs_params[6].x;\n        vec3 _8060 = _6616;\n        _8060.x = _6621.x;\n        _8060.y = _6621.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _8060;\n        _7852 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6649 = fa_tex_fix(param_12, param_13);\n    vec4 _8063 = mrt;\n    _8063.x = _6649.x;\n    _8063.y = _6649.y;\n    _8063.z = _6649.z;\n    mrt = _8063;\n    vec4 _6677 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6677.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6688 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6718 = fa_tex_fix(param_20, param_21);\n    float _7857 = fa_mesh_fs_params[20].x;\n    float _7858 = fa_mesh_fs_params[20].y;\n    float _7861 = fa_mesh_fs_params[20].z;\n    float _7860 = fa_mesh_fs_params[21].w;\n    float _7863 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7857 *= _6688.y;\n            _7858 *= _6688.z;\n            _7860 *= _6677.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7861 *= mrt.x;\n            _7863 *= mrt.w;\n        }\n    }\n    return Surface(_6581.xyz, _6581.w, _7852, clamp(fa_mesh_fs_params[5].x * _6649.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6649.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6688.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6718), _7857, _7858, fa_mesh_fs_params[21].xyz, _7860, _7861, fa_mesh_fs_params[20].w, _7863, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1771 = rect.zw - rect.xy;\n    vec2 _1775 = _1771 * atlas;\n    vec2 _1779 = ddx * _1775;\n    vec2 _1783 = ddy * _1775;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1771), clamp(0.5 * log2(max(max(dot(_1779, _1779), dot(_1783, _1783)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1816 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1823;\n    if (!_1816)\n    {\n        _1823 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1823 = _1816;\n    }\n    if (_1823)\n    {\n        return;\n    }\n    vec3 _1829 = dFdx(world_pos);\n    vec3 _1832 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1836 = fa_cluster_texel(param);\n    int _1840 = int(_1836.w);\n    if (_1840 < 1)\n    {\n        return;\n    }\n    int _1850 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1850;\n    vec4 _1854 = fa_light_texel(param_1);\n    vec2 _1857 = _1854.yz;\n    int _1861 = int(_1854.w);\n    int param_2 = _1850 + 1;\n    vec4 _1866 = fa_light_texel(param_2);\n    float _1867 = _1866.x;\n    int _1873 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1877 = int(_1836.z);\n    vec3 _2142;\n    for (int k = 0; k < _1840; k++)\n    {\n        int _1890 = _1877 + k;\n        int param_3 = _1861 + (_1890 >> 2);\n        int _1907 = (_1850 + 2) + (int(fa_light_texel(param_3)[_1890 & 3]) * 7);\n        int param_4 = _1907 + 6;\n        vec4 _1912 = fa_light_texel(param_4);\n        if (((int(_1912.w + 0.5) >> _1873) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1907;\n        vec4 _1927 = fa_light_texel(param_5);\n        int param_6 = _1907 + 1;\n        vec4 _1932 = fa_light_texel(param_6);\n        int param_7 = _1907 + 2;\n        vec4 _1937 = fa_light_texel(param_7);\n        vec3 _1940 = _1927.xyz;\n        float _1945 = dot(_1940, world_pos) + _1927.w;\n        vec3 _1947 = _1932.xyz;\n        float _1952 = dot(_1947, world_pos) + _1932.w;\n        vec3 _1954 = _1937.xyz;\n        float _1959 = dot(_1954, world_pos) + _1937.w;\n        bool _1964 = abs(_1945) > 0.5;\n        bool _1972;\n        if (!_1964)\n        {\n            _1972 = abs(_1952) > 0.5;\n        }\n        else\n        {\n            _1972 = _1964;\n        }\n        bool _1980;\n        if (!_1972)\n        {\n            _1980 = abs(_1959) > 0.5;\n        }\n        else\n        {\n            _1980 = _1972;\n        }\n        if (_1980)\n        {\n            continue;\n        }\n        float _1995 = clamp(dot(geo_normal, normalize(_1954)) * _1912.z, 0.0, 1.0);\n        if (_1995 <= 0.0)\n        {\n            continue;\n        }\n        float _2015 = (clamp((0.5 - abs(_1959)) * 10.0, 0.0, 1.0) * _1995) * _1912.x;\n        vec2 _2023 = vec2(_1945 + 0.5, 0.5 - _1952);\n        vec2 _2033 = vec2(dot(_1940, _1829), dot(_1947, _1829));\n        vec2 _2043 = vec2(dot(_1940, _1832), dot(_1947, _1832));\n        int param_8 = _1907 + 5;\n        vec4 _2048 = fa_light_texel(param_8);\n        int param_9 = _1907 + 3;\n        vec4 _2053 = fa_light_texel(param_9);\n        int param_10 = _1907 + 4;\n        vec4 _2058 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2048.xyz;\n        bool _2068 = _2053.z > _2053.x;\n        if (_2068)\n        {\n            vec4 param_11 = _2053;\n            vec2 param_12 = _2023;\n            vec2 param_13 = _1857;\n            vec2 param_14 = _2033;\n            vec2 param_15 = _2043;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1867 > 0.5) && (_1867 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2094 = fa_dc_to_linear(param_16);\n                vec4 _7932 = tx;\n                _7932.x = _2094.x;\n                _7932.y = _2094.y;\n                _7932.z = _2094.z;\n                tx = _7932;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2015 * tex_a) * _2048.w, 0.0, 1.0)));\n        if (_2058.z > _2058.x)\n        {\n            vec4 param_17 = _2058;\n            vec2 param_18 = _2023;\n            vec2 param_19 = _1857;\n            vec2 param_20 = _2033;\n            vec2 param_21 = _2043;\n            vec4 _2138 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1867 > 1.5)\n            {\n                vec3 param_22 = _2138.xyz;\n                vec3 _2148 = fa_dc_to_srgb(param_22);\n                _2142 = _2148;\n            }\n            else\n            {\n                _2142 = _2138.xyz;\n            }\n            vec3 _2157 = (_2142 * 2.0) - vec3(1.0);\n            vec2 _2162 = _2157.xy * _1912.y;\n            vec3 _2184 = (normalize(_1940) * _2162.x) + (normalize(_1947) * _2162.y);\n            vec3 _2187 = normalize(normal);\n            normal = normalize(mix(_2187, normalize((_2187 * max(_2157.z, 0.0500000007450580596923828125)) + (_2184 - (_2187 * dot(_2187, _2184)))), vec3(clamp(_2015 * (_2068 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4211 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4218 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4221 = int(_4211);\n    int _4224 = int(_4218);\n    float _4234 = _4218 - float(_4224);\n    int _4289 = (_4221 * 9) + _4224;\n    int _4309 = ((_4221 + 1) * 9) + _4224;\n    return mix(mix(_4285[_4289], _4285[_4289 + 1], _4234), mix(_4285[_4309], _4285[_4309 + 1], _4234), _4211 - float(_4221));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7775 = false;\n    float _7776 = 1.0;\n    float _7777 = 1.0;\n    float _7778 = 1.0;\n    float _7779 = 0.0;\n    float _7780 = 0.0;\n    float _7781 = 0.0;\n    float _7782 = 0.0;\n    float _7784 = 1.0;\n    bool _7785 = false;\n    vec3 _7786 = vec3(0.0);\n    float _7787 = 1.0;\n    float _7788 = 1.0;\n    float _7789 = 1.0;\n    float _7790 = 0.0;\n    float _7791 = 0.0;\n    vec3 _7792 = vec3(1.0, 0.0, 0.0);\n    vec3 _7793 = vec3(0.0, 0.0, 1.0);\n    float _7794 = 1.0;\n    float _7795 = 1.0;\n    float _4360 = clamp(s.specular, 0.0, 1.0);\n    float _4364 = clamp(s.ior, 1.0, 3.0);\n    bool _4369 = (_4360 != 1.0) || (_4364 != 1.5);\n    bool _4378;\n    if (!_4369)\n    {\n        _4378 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4378 = _4369;\n    }\n    if (_4378)\n    {\n        float _4386 = (_4364 - 1.0) / (_4364 + 1.0);\n        f0 = mix(min(vec3(_4386 * _4386) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4360, s.albedo, vec3(metallic));\n        _7776 = mix(_4360, 1.0, metallic);\n        _7775 = true;\n    }\n    float _4413 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4413 > 0.0)\n    {\n        float _4421 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7779 = _4413;\n        _7780 = _4421;\n        float _4428 = _4421 * _4421;\n        _7781 = _4428;\n        _7782 = _4428 * _4428;\n        float _4440 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7784 = _4440;\n        _7777 = 1.0 - (_4413 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4440, 0.0, 1.0), 5.0))));\n        _7775 = true;\n    }\n    vec3 _4459 = max(s.sheen_color, vec3(0.0));\n    float _4468 = max(_4459.x, max(_4459.y, _4459.z));\n    if (_4468 > 0.0)\n    {\n        float _4476 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7785 = true;\n        _7786 = _4459;\n        _7787 = _4476;\n        _7788 = _4476 * _4476;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4476;\n        float _4493 = fa_sheen_albedo(param, param_1);\n        _7790 = _4493;\n        _7789 = 1.0 - min(_4468 * _4493, 1.0);\n        _7775 = true;\n    }\n    _7778 = _7777 * _7789;\n    float _4512 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4512 != 0.0)\n    {\n        vec3 _4527 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4527;\n        if (dot(_4527, _4527) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4539 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4539.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4539.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4539.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4543 = t;\n        vec3 _4544 = normalize(_4543);\n        t = _4544;\n        vec3 _4569 = normalize((_4544 * cos(s.anisotropy_rotation)) + ((cross(n, _4544) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7792 = _4569;\n        _7793 = cross(n, _4569);\n        float _4579 = roughness * roughness;\n        float _4585 = mix(_4579, 1.0, _4512 * _4512);\n        bool _4587 = _4512 > 0.0;\n        _7794 = _4587 ? _4585 : _4579;\n        _7795 = _4587 ? _4579 : _4585;\n        _7791 = _4512;\n        _7775 = true;\n    }\n    return FaLayers(_7775, _7776, _7777, _7778, _7779, _7780, _7781, _7782, i.world_normal, _7784, _7785, _7786, _7787, _7788, _7789, _7790, _7791, _7792, _7793, _7794, _7795);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[39].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3382 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3382;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3992 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 amb = vec3(0.0);\n    bool _3997 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3992 > 0.0005000000237487256526947021484375)\n    {\n        if (_3997)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[39].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3992;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3992;\n        }\n    }\n    bool _4048 = fa_mesh_fs_params[40].w > 0.0;\n    if (_4048)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[40].xy;\n            float param_4 = fa_mesh_fs_params[40].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[40].w);\n        }\n    }\n    bool _4079 = fa_mesh_fs_params[45].w > 0.0;\n    if (_4079)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[45].xy;\n            float param_7 = fa_mesh_fs_params[45].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[45].w);\n        }\n    }\n    if ((_3997 || _4048) || _4079)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5353;\n    if (fa_lm.z > 0.5)\n    {\n        _5353 = 0.0;\n    }\n    else\n    {\n        _5353 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _5364 = _5353 < 1.0;\n    bool _5370;\n    if (_5364)\n    {\n        int param = li;\n        _5370 = fa_light_baked(param);\n    }\n    else\n    {\n        _5370 = _5364;\n    }\n    return _5370 ? _5353 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _789 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _802 = (c - (ru * hx)) - p;\n        vec3 _808 = ru * (2.0 * hx);\n        float _814 = max(dot(_808, _808), 9.9999999392252902907785028219223e-09);\n        float _818 = dot(_802, _808);\n        float t = clamp((-_818) / _814, 0.0, 1.0);\n        if (_789)\n        {\n            float _833 = dot(r, _808);\n            float _839 = _814 - (_833 * _833);\n            if (abs(_839) > (9.9999997473787516355514526367188e-06 * _814))\n            {\n                t = clamp(((dot(r, _802) * _833) - _818) / _839, 0.0, 1.0);\n            }\n        }\n        return (p + _802) + (_808 * t);\n    }\n    vec3 q = p;\n    float _871 = dot(r, axis);\n    bool _879;\n    if (_789)\n    {\n        _879 = abs(_871) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _879 = _789;\n    }\n    if (_879)\n    {\n        float _889 = dot(c - p, axis) / _871;\n        if (_889 > 0.0)\n        {\n            q = p + (r * _889);\n        }\n    }\n    vec3 _902 = q - c;\n    vec2 xy = vec2(dot(_902, ru), dot(_902, uu));\n    if (shape > 0.5)\n    {\n        float _917 = length(xy);\n        if (_917 > hx)\n        {\n            xy *= (hx / _917);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _550 = abs(d);\n    float _552 = _550.x;\n    float _554 = _550.y;\n    bool _555 = _552 >= _554;\n    bool _563;\n    if (_555)\n    {\n        _563 = _552 >= _550.z;\n    }\n    else\n    {\n        _563 = _555;\n    }\n    int _564;\n    if (_563)\n    {\n        _564 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _579;\n        if (_554 >= _550.z)\n        {\n            _579 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _579 = (d.z > 0.0) ? 4 : 5;\n        }\n        _564 = _579;\n    }\n    return _564;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _709 = dot(d, right);\n    float _713 = dot(d, up);\n    float _724;\n    if (((_709 * _709) + (_713 * _713)) > 1.0000000133514319600180897396058e-10)\n    {\n        _724 = atan(_713, _709) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _724 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_724 - floor(_724)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _955 = fa_light_base(param);\n    bool _959 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _955;\n    vec4 _963 = fa_light_texel(param_1);\n    int param_2 = _955 + 1;\n    vec4 _968 = fa_light_texel(param_2);\n    float _971 = _968.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _983 = _959 && (_971 > 2.5);\n    fa_light_is_area = _983;\n    bool _985 = _971 < 0.5;\n    vec3 l;\n    if (_985)\n    {\n        l = normalize(_963.xyz);\n        if (_959)\n        {\n            int param_3 = _955 + 6;\n            vec4 _999 = fa_light_texel(param_3);\n            if (_999.z > 0.5)\n            {\n                int param_4 = _955 + 4;\n                vec4 _1009 = fa_light_texel(param_4);\n                int param_5 = _955 + 5;\n                vec4 _1014 = fa_light_texel(param_5);\n                vec2 param_6 = _999.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1009.xyz) * _1009.w, (-dot(world_pos, _1014.xyz)) * _1014.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1044 = _963.xyz;\n        vec3 _1046 = _1044 - world_pos;\n        vec3 to_light = _1046;\n        float _1049 = length(_1046);\n        float reach = _1049;\n        bool front = true;\n        if (_983)\n        {\n            int param_8 = _955 + 7;\n            reach = max(_1049 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _955 + 4;\n            vec4 _1073 = fa_light_texel(param_9);\n            int param_10 = _955 + 5;\n            vec4 _1078 = fa_light_texel(param_10);\n            int param_11 = _955 + 6;\n            vec4 _1083 = fa_light_texel(param_11);\n            float _1084 = _1083.w;\n            int param_12 = _955 + 2;\n            vec3 _1091 = normalize(fa_light_texel(param_12).xyz);\n            bool _1093 = _1084 > 1.5;\n            bool _1101;\n            if (!_1093)\n            {\n                _1101 = dot(_1091, to_light) < 0.0;\n            }\n            else\n            {\n                _1101 = _1093;\n            }\n            front = _1101;\n            vec3 r = vec3(0.0);\n            vec3 _1110 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1114 = dot(n, n) > 0.5;\n            bool _1122;\n            if (_1114)\n            {\n                _1122 = dot(_1110, _1110) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1122 = _1114;\n            }\n            if (_1122)\n            {\n                r = reflect(-normalize(_1110), normalize(n));\n            }\n            vec3 param_13 = _1044;\n            vec3 param_14 = _1091;\n            vec3 param_15 = _1073.xyz;\n            vec3 param_16 = _1078.xyz;\n            float param_17 = _1073.w;\n            float param_18 = _1078.w;\n            float param_19 = _1084;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1158 = length(to_light);\n        dist = _1158;\n        l = to_light / vec3(max(_1158, 9.9999997473787516355514526367188e-05));\n        float _1172 = reach / max(_963.w, 0.001000000047497451305389404296875);\n        float _1178 = clamp(1.0 - (_1172 * _1172), 0.0, 1.0);\n        float _1180;\n        if (front)\n        {\n            _1180 = _1178 * _1178;\n        }\n        else\n        {\n            _1180 = 0.0;\n        }\n        atten = _1180;\n        bool _1191 = _971 < 2.5;\n        if ((_971 > 1.5) && _1191)\n        {\n            int param_22 = _955 + 2;\n            vec4 _1199 = fa_light_texel(param_22);\n            float _1209 = _1199.w;\n            int param_23 = _955 + 3;\n            vec4 _1214 = fa_light_texel(param_23);\n            float _1215 = _1214.x;\n            float cos_inner = _1215;\n            if (_1215 > 1.5)\n            {\n                cos_inner = mix(_1209, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1209, cos_inner, dot(-l, normalize(_1199.xyz)));\n        }\n        if (_959 && (_971 < 1.5))\n        {\n            int param_24 = _955 + 6;\n            vec4 _1239 = fa_light_texel(param_24);\n            if (_1239.z > 0.5)\n            {\n                vec3 _1247 = -to_light;\n                int param_25 = _955 + 4;\n                int param_26 = _955 + 5;\n                vec3 _1261 = fa_light_texel(param_25).xyz;\n                vec3 _1265 = fa_light_texel(param_26).xyz;\n                vec3 _1274 = vec3(dot(_1247, _1261), dot(_1247, _1265), dot(_1247, cross(_1261, _1265)));\n                vec3 param_27 = _1274;\n                int _1278 = fa_cube_face(param_27);\n                int param_28 = _1278;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1305 = vec2(dot(_1274, cross(param_29, param_30)), dot(_1274, param_30)) / vec2(max(dot(_1274, param_29), 9.9999997473787516355514526367188e-05));\n                int _1309 = _1278 / 3;\n                vec2 param_31 = _1239.xy + (vec2(float(_1278 - (_1309 * 3)), float(_1309)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1305.x), 0.5 - (0.5 * _1305.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _955 + 7;\n            vec4 _1339 = fa_light_texel(param_33);\n            if (_1339.z > 0.5)\n            {\n                int param_34 = _955 + 2;\n                int param_35 = _955 + 4;\n                int param_36 = _955 + 5;\n                vec2 param_37 = _1339.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_959 && _1191)\n            {\n                int param_42 = _955 + 6;\n                vec4 _1386 = fa_light_texel(param_42);\n                int param_43 = _955 + 7;\n                vec4 _1391 = fa_light_texel(param_43);\n                bool _1394 = _1386.z > 0.5;\n                bool _1401;\n                if (!_1394)\n                {\n                    _1401 = _1391.z > 0.5;\n                }\n                else\n                {\n                    _1401 = _1394;\n                }\n                if (_1401)\n                {\n                    int param_44 = _955 + 2;\n                    vec4 _1408 = fa_light_texel(param_44);\n                    vec3 _1412 = normalize(_1408.xyz);\n                    int param_45 = _955 + 4;\n                    vec4 _1417 = fa_light_texel(param_45);\n                    int param_46 = _955 + 5;\n                    vec4 _1422 = fa_light_texel(param_46);\n                    if (_1394)\n                    {\n                        vec3 _1430 = -to_light;\n                        float _1437 = _1408.w;\n                        float _1453 = 0.5 / max(dot(_1430, _1412) * (sqrt(max(1.0 - (_1437 * _1437), 0.0)) / max(_1437, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1386.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1430, _1417.xyz) * _1453), 0.5 - (dot(_1430, _1422.xyz) * _1453));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1391.z > 0.5)\n                    {\n                        vec2 param_49 = _1391.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1412;\n                        vec3 param_52 = _1417.xyz;\n                        vec3 param_53 = _1422.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7763 = _968.xyz * atten;\n    if (_959)\n    {\n        _7763 *= fa_light_tint;\n    }\n    int _1522;\n    if (_985)\n    {\n        _1522 = 0;\n    }\n    else\n    {\n        _1522 = ((_971 > 1.5) && (_971 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7763, atten, 1.0, dist, _1522);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2259;\n    if (i == 0)\n    {\n        _2259 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2275;\n        if (i == 1)\n        {\n            _2275 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2283;\n            if (i == 2)\n            {\n                _2283 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2283 = fa_shadows[24].w;\n            }\n            _2275 = _2283;\n        }\n        _2259 = _2275;\n    }\n    return _2259;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2316 = fa_shadow_depth(param, param_1);\n    float _2320;\n    if (conv.x < 0.5)\n    {\n        _2320 = _2316;\n    }\n    else\n    {\n        _2320 = (conv.y * conv.z) / (conv.z - (_2316 * (conv.z - conv.y)));\n    }\n    return _2320;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2247 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2247), sin(_2247)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2366 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2375;\n        if (k < 0.0)\n        {\n            _2375 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2375 = k;\n        }\n        float _2395 = clamp((_2375 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2366;\n            vec2 _2414 = fa_shadow_vogel(param_3, param_4, param_5) * _2395;\n            vec2 param_6 = uv + (_2414 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2426 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2426 < (zr - (length(_2414) * plane)))\n            {\n                sum += _2426;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2452 = sum / cnt;\n        float _2462;\n        if (k < 0.0)\n        {\n            _2462 = (-k) / max(_2452, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2462 = k;\n        }\n        radius = clamp(((max(zr - _2452, 0.0) * unit) * _2462) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2484 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2484; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2484;\n        float param_11 = _2366;\n        vec2 _2503 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2503 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2503) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2484);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2545 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2550 = clamp(dot(n, l), 0.0, 1.0);\n    float _2556 = sqrt(1.0 - (_2550 * _2550));\n    float _2563 = min(_2556 / max(_2550, 0.20000000298023223876953125), 4.0);\n    float _2568;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2568 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2568 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2593 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2568 * _2556)), 1.0);\n    float _2600 = _2593.x;\n    bool _2603 = _2600 < fa_shadows[ci * 1 + 16].x;\n    bool _2612;\n    if (!_2603)\n    {\n        _2612 = _2600 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2612 = _2603;\n    }\n    bool _2621;\n    if (!_2612)\n    {\n        _2621 = _2593.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2621 = _2612;\n    }\n    bool _2630;\n    if (!_2621)\n    {\n        _2630 = _2593.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2630 = _2621;\n    }\n    bool _2637;\n    if (!_2630)\n    {\n        _2637 = _2593.z > 1.0;\n    }\n    else\n    {\n        _2637 = _2630;\n    }\n    if (_2637)\n    {\n        return -1.0;\n    }\n    float _2645;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2645 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2645 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2593.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2593.z - ((_2645 * (1.0 + (0.5 * _2563))) / _2545);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2545;\n    float param_5 = _2545 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2563, 3.0)) * 0.5) / _2545;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3023 = int(fa_shadows[25].x + 0.5);\n    if (_3023 < 1)\n    {\n        return 1.0;\n    }\n    float _3038 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3023 - 1;\n    if (_3038 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3050 = _3023 > 1;\n    bool _3057;\n    if (_3050)\n    {\n        _3057 = _3038 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3057 = _3050;\n    }\n    if (_3057)\n    {\n        ci = 1;\n    }\n    bool _3061 = _3023 > 2;\n    bool _3068;\n    if (_3061)\n    {\n        _3068 = _3038 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3068 = _3061;\n    }\n    if (_3068)\n    {\n        ci = 2;\n    }\n    bool _3072 = _3023 > 3;\n    bool _3079;\n    if (_3072)\n    {\n        _3079 = _3038 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3079 = _3072;\n    }\n    if (_3079)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3023)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3105 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3105;\n        if (_3105 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3130;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3130 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3130 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3149 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3130, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3160 = clamp((_3038 - (fa_shadow_split_at(param_7) - _3149)) / _3149, 0.0, 1.0);\n        if (_3160 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3023)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3181 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3181;\n                if (_3181 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3160);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2703 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2710;\n    if (!_2703)\n    {\n        _2710 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2710 = _2703;\n    }\n    if (_2710)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2723 = fa_light_texel(param);\n    float _2724 = _2723.x;\n    if (_2724 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2733 = int(_2724 + 0.5);\n    int param_1 = _2733;\n    vec4 _2737 = fa_light_texel(param_1);\n    int param_2 = _2733 + 1;\n    vec4 _2742 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2745 = _2737.y;\n    if (_2745 > 0.0)\n    {\n        float _2762 = 1.0 - smoothstep(0.75 * _2745, _2745, length(world - fa_shadows[27].xyz));\n        fade = _2762;\n        if (_2762 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2737.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2786 = (_2733 + 2) + (face * 6);\n    int param_4 = _2786;\n    int param_5 = _2786 + 1;\n    int param_6 = _2786 + 3;\n    vec4 _2800 = fa_light_texel(param_6);\n    int param_7 = _2786 + 4;\n    vec4 _2805 = fa_light_texel(param_7);\n    int param_8 = _2786 + 5;\n    vec4 _2810 = fa_light_texel(param_8);\n    float _2822 = _2810.x * max(dot(_2800, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2827 = clamp(dot(n, l), 0.0, 1.0);\n    float _2850 = clamp(dot(n, _2800.xyz), -1.0, 1.0);\n    float _2869 = min(sqrt(1.0 - (_2850 * _2850)) / max(abs(dot(n, world - lpos)) / max(dot(_2800, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2872 = _2742.y;\n    float _2874;\n    if (_2872 > 0.0)\n    {\n        _2874 = _2872;\n    }\n    else\n    {\n        _2874 = 1.5 * _2822;\n    }\n    vec4 _2894 = vec4(world + (n * (_2874 * sqrt(1.0 - (_2827 * _2827)))), 1.0);\n    float _2898 = dot(_2800, _2894);\n    float _2901 = _2810.y;\n    if (_2898 < _2901)\n    {\n        return 1.0;\n    }\n    vec2 _2916 = vec2(dot(fa_light_texel(param_4), _2894), dot(fa_light_texel(param_5), _2894)) / vec2(_2898);\n    float _2918 = _2916.x;\n    bool _2921 = _2918 < _2805.x;\n    bool _2930;\n    if (!_2921)\n    {\n        _2930 = _2918 > _2805.z;\n    }\n    else\n    {\n        _2930 = _2921;\n    }\n    bool _2939;\n    if (!_2930)\n    {\n        _2939 = _2916.y < _2805.y;\n    }\n    else\n    {\n        _2939 = _2930;\n    }\n    bool _2948;\n    if (!_2939)\n    {\n        _2948 = _2916.y > _2805.w;\n    }\n    else\n    {\n        _2948 = _2939;\n    }\n    if (_2948)\n    {\n        return 1.0;\n    }\n    float _2954 = _2742.x;\n    float _2956;\n    if (_2954 > 0.0)\n    {\n        _2956 = _2954;\n    }\n    else\n    {\n        _2956 = 1.5 * _2822;\n    }\n    vec2 param_9 = _2916;\n    vec4 param_10 = _2805;\n    float param_11 = _2898 - (_2956 * (1.0 + (0.5 * _2869)));\n    float param_12 = _2822;\n    float param_13 = 1.0;\n    float param_14 = _2810.z * 0.25;\n    float param_15 = (_2822 * min(_2869, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2901, _2810.z);\n    int param_17 = int(_2737.z + 0.5);\n    float param_18 = _2737.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5097 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5104;\n    if (!_5097)\n    {\n        _5104 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5104 = _5097;\n    }\n    if (_5104)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5117 = fa_light_texel(param);\n    float _5118 = _5117.y;\n    float len = _5118;\n    if (_5118 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5130 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5140 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5130);\n    if (_5140 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5146 = len;\n    float _5149 = min(_5146, 0.89999997615814208984375 * dist);\n    len = _5149;\n    float _5154 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5130);\n    float _5159 = _5154 + (0.5 * _5149);\n    vec3 _5165 = world + (gn * _5154);\n    float _5167 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5231;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5182 = (float(k) + _5167) * 0.083333335816860198974609375;\n        vec3 _5190 = _5165 + (l * (_5182 * len));\n        vec4 _5196 = vec4(_5190, 1.0);\n        float _5202 = dot(fa_mesh_fs_params[28], _5196);\n        if (_5202 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5222 = vec2(dot(fa_mesh_fs_params[26], _5196), dot(fa_mesh_fs_params[27], _5196)) / vec2(_5202);\n        float _5226 = _5222.x * 0.5;\n        float _5227 = _5226 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5231 = (_5222.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5231 = 0.5 - (_5222.y * 0.5);\n        }\n        bool _5247 = _5227 < 0.0;\n        bool _5254;\n        if (!_5247)\n        {\n            _5254 = _5227 >= 1.0;\n        }\n        else\n        {\n            _5254 = _5247;\n        }\n        bool _5261;\n        if (!_5254)\n        {\n            _5261 = _5231 < 0.0;\n        }\n        else\n        {\n            _5261 = _5254;\n        }\n        bool _5268;\n        if (!_5261)\n        {\n            _5268 = _5231 >= 1.0;\n        }\n        else\n        {\n            _5268 = _5261;\n        }\n        if (_5268)\n        {\n            break;\n        }\n        vec4 _5287 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_5227, _5231) * fa_mesh_fs_params[24].zw), 0);\n        if (_5287.w < 0.5)\n        {\n            continue;\n        }\n        float _5306 = (dot(fa_mesh_fs_params[29].xyz, _5190) + fa_mesh_fs_params[29].w) - _5287.x;\n        if ((_5306 > _5154) && (_5306 < _5159))\n        {\n            occ = max(occ, (1.0 - (_5182 * _5182)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5227, 0.5 - _5226), min(_5231, 1.0 - _5231))));\n        }\n    }\n    return 1.0 - (occ * _5140);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5409 = fa_baked_keep(param);\n    if (_5409 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5435 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7832 = _5435.color;\n    float _7833 = _5435.attenuation;\n    float _7834 = _5435.shadow;\n    bool _5438 = _5435.type == 0;\n    if (_5438 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5435.direction;\n        float _5449 = fa_shadow_factor(param_5, param_6);\n        _7834 = _5449;\n        _7832 *= _5449;\n    }\n    else\n    {\n        bool _5460 = _5435.type != 0;\n        bool _5466;\n        if (_5460)\n        {\n            _5466 = _7833 > 0.0;\n        }\n        else\n        {\n            _5466 = _5460;\n        }\n        if (_5466)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5435.direction;\n            float _5485 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7834 = _5485;\n            _7832 *= _5485;\n        }\n    }\n    bool _5495 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5501;\n    if (_5495)\n    {\n        _5501 = _7833 > 0.0;\n    }\n    else\n    {\n        _5501 = _5495;\n    }\n    if (_5501)\n    {\n        float _5508;\n        if (_5438)\n        {\n            _5508 = 1000000000.0;\n        }\n        else\n        {\n            _5508 = _5435._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5435.direction;\n        float param_18 = _5508;\n        float _5526 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7834 *= _5526;\n        _7832 *= _5526;\n    }\n    float _5539 = _7833;\n    float _5540 = _5539 * _5409;\n    _7833 = _5540;\n    vec3 _5544 = _7832;\n    vec3 _5545 = _5544 * _5409;\n    _7832 = _5545;\n    return LightSample(_5435.direction, _5545, _5540, _7834, _5435._distance, _5435.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5579 = v - (n * dot(v, n));\n    vec3 t = _5579;\n    float _5583 = dot(_5579, _5579);\n    float l2 = _5583;\n    if (_5583 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5593;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5593 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5593 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5593;\n        l2 = dot(_5593, _5593);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5628 = dot(a, a);\n    float _5632 = dot(b, b);\n    if ((_5628 < 1.0000000195414813782625560981111e-24) || (_5632 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5646 = a * inversesqrt(_5628);\n    vec3 _5651 = b * inversesqrt(_5632);\n    float _5655 = dot(_5646, _5651);\n    float _5658 = abs(_5655);\n    float g = (((((((((((0.0416471660137176513671875 * _5658) - 0.1924748718738555908203125) * _5658) + 0.4179156124591827392578125) * _5658) - 0.616057217121124267578125) * _5658) + 0.777722418308258056640625) * _5658) - 0.999542415142059326171875) * _5658) + 1.570791721343994140625;\n    if (_5655 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5655 * _5655), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5646, _5651) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5715 = a.z > 0.0;\n    bool _5719 = b.z > 0.0;\n    if (_5715 && _5719)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5715 != _5719)\n        {\n            vec3 _5754 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5754.z = 0.0;\n            if (_5715)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5754;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5754;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5754;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5754;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5803 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5829 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5855 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5881 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5803;\n    vec3 param_1 = _5829;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5829;\n    vec3 param_7 = _5855;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5855;\n    vec3 param_13 = _5881;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5881;\n    vec3 param_19 = _5803;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6031 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6055 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6071 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6031;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6055;\n    vec4 param_9 = m;\n    vec3 param_10 = _6031;\n    vec3 param_11 = _6055;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6071;\n    vec4 param_14 = m;\n    vec3 param_15 = _6031;\n    vec3 param_16 = _6071;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6129 = fa_light_base(param);\n    int param_1 = _6129;\n    int param_2 = _6129 + 1;\n    int param_3 = _6129 + 2;\n    int param_4 = _6129 + 4;\n    vec4 _6151 = fa_light_texel(param_4);\n    int param_5 = _6129 + 5;\n    vec4 _6156 = fa_light_texel(param_5);\n    int param_6 = _6129 + 6;\n    vec4 _6161 = fa_light_texel(param_6);\n    float _6162 = _6161.w;\n    vec3 _6167 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6169 = _6162 < 1.5;\n    bool _6176;\n    if (_6169)\n    {\n        _6176 = dot(normalize(fa_light_texel(param_3).xyz), _6167) >= 0.0;\n    }\n    else\n    {\n        _6176 = _6169;\n    }\n    if (_6176)\n    {\n        return vec3(0.0);\n    }\n    bool _6185 = (_6162 > 0.5) && _6169;\n    float _6189 = _6185 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6192 = _6151.xyz;\n    float _6194 = _6151.w;\n    vec3 _6200 = _6156.xyz;\n    float _6202 = _6156.w;\n    vec3 up = _6200 * (_6202 * _6189);\n    float _6208;\n    if (_6185)\n    {\n        _6208 = (3.1415927410125732421875 * _6194) * _6194;\n    }\n    else\n    {\n        _6208 = (4.0 * _6194) * _6202;\n    }\n    if (_6162 > 1.5)\n    {\n        vec3 _6234 = cross(_6192, -_6167);\n        vec3 perp = _6234;\n        float _6238 = dot(_6234, _6234);\n        vec3 _6241;\n        if (_6238 > 1.0000000133514319600180897396058e-10)\n        {\n            _6241 = perp * inversesqrt(_6238);\n        }\n        else\n        {\n            _6241 = _6200;\n        }\n        perp = _6241;\n        up = _6241 * _6202;\n    }\n    float _6262 = max(_6208, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6272 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6272;\n    vec3 param_10 = n;\n    vec3 param_11 = _6167;\n    vec3 _6280 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6272;\n    vec3 param_13 = n;\n    vec3 param_14 = _6192 * (_6194 * _6189);\n    vec3 _6288 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6272;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6296 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6162;\n    vec3 param_20 = _6280;\n    vec3 param_21 = _6288;\n    vec3 param_22 = _6296;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6315 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6315;\n    vec2 param_26 = _6315 + vec2(64.0, 0.0);\n    vec4 _6325 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6162;\n    vec3 param_29 = _6280;\n    vec3 param_30 = _6288;\n    vec3 param_31 = _6296;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6325.x) + ((vec3(f90) - f0) * _6325.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6167, _6167)) + _6262) / _6262) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4834 = 1.0 / alpha;\n    return ((2.0 + _4834) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4834)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4869 = max(dot(L.nc, l), 0.0);\n    float _4875 = max(dot(L.nc, h), 0.0);\n    float _4884 = ((_4875 * _4875) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4884) * _4884)) * (0.5 / max(mix((2.0 * _4869) * L.coat_ndv, _4869 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4869)) * _4869;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6393;\n    if (L.sheen_on)\n    {\n        _6393 = L.sheen_scale;\n    }\n    else\n    {\n        _6393 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6393);\n    vec3 _6406 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6417 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6426 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6406), 0.0);\n        float param_13 = _6426;\n        float param_14 = ndv;\n        result += ((L.sheen * _6417) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6426)) * _6426) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6406;\n        float param_18 = max(dot(v, _6406), 0.0);\n        result += (_6417 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4737 = tdh / at;\n    float _4741 = bdh / ab;\n    float _4753 = ((_4737 * _4737) + (_4741 * _4741)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4753) * _4753);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4933 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5012 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5012) * _5012);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4933);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4933));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4143 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4146 = _4143.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4146 * _4146, exp2((-9.27999973297119140625) * ndv)) * _4146) + _4143.y)) + _4143.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3402 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3405 = _3402.x;\n    float _3407 = _3402.z;\n    vec2 e = vec2(_3405, _3407);\n    if (_3402.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3407)) * ((_3405 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3405)) * ((_3407 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3454;\n    if (lv == 0)\n    {\n        _3454 = 0.0;\n    }\n    else\n    {\n        _3454 = res + 2.0;\n    }\n    float _3464;\n    if (lv == 0)\n    {\n        _3464 = 0.0;\n    }\n    else\n    {\n        _3464 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3454, _3464)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3509;\n    if (res > 64.5)\n    {\n        _3509 = 5.0;\n    }\n    else\n    {\n        _3509 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3524 = clamp(rough, 0.0, 1.0) * (_3509 - 1.0);\n    int _3531 = int(min(floor(_3524), _3509 - 2.0));\n    float _3536 = _3524 - float(_3531);\n    vec3 param = d;\n    vec2 _3540 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3531;\n    vec2 param_4 = _3540;\n    vec3 _3550 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3536 < 0.00200000009499490261077880859375)\n    {\n        return _3550;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3531 + 1;\n    vec2 param_8 = _3540;\n    return mix(_3550, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3536));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3620 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3627 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3634 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3640 = dot(bx.xyz, d);\n    float _3644 = dot(by.xyz, d);\n    float _3648 = dot(bz.xyz, d);\n    float _3654;\n    if (_3640 > 9.9999999747524270787835121154785e-07)\n    {\n        _3654 = (1.0 - _3620) / _3640;\n    }\n    else\n    {\n        float _3668;\n        if (_3640 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3668 = ((-1.0) - _3620) / _3640;\n        }\n        else\n        {\n            _3668 = 1000000015047466219876688855040.0;\n        }\n        _3654 = _3668;\n    }\n    float tx = _3654;\n    float _3685;\n    if (_3644 > 9.9999999747524270787835121154785e-07)\n    {\n        _3685 = (1.0 - _3627) / _3644;\n    }\n    else\n    {\n        float _3698;\n        if (_3644 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3698 = ((-1.0) - _3627) / _3644;\n        }\n        else\n        {\n            _3698 = 1000000015047466219876688855040.0;\n        }\n        _3685 = _3698;\n    }\n    float ty = _3685;\n    float _3714;\n    if (_3648 > 9.9999999747524270787835121154785e-07)\n    {\n        _3714 = (1.0 - _3634) / _3648;\n    }\n    else\n    {\n        float _3727;\n        if (_3648 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3727 = ((-1.0) - _3634) / _3648;\n        }\n        else\n        {\n            _3727 = 1000000015047466219876688855040.0;\n        }\n        _3714 = _3727;\n    }\n    float _3739 = tx;\n    float _3742 = (_3739 > 0.0) ? _3739 : 1000000015047466219876688855040.0;\n    tx = _3742;\n    float _3743 = ty;\n    float _3746 = (_3743 > 0.0) ? _3743 : 1000000015047466219876688855040.0;\n    ty = _3746;\n    float _3756 = min(_3742, min(_3746, (_3714 > 0.0) ? _3714 : 1000000015047466219876688855040.0));\n    if (_3756 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3772 = (fa_world_pos + (d * _3756)) - posw.xyz;\n    vec3 _3777;\n    if (dot(_3772, _3772) > 1.0000000133514319600180897396058e-10)\n    {\n        _3777 = normalize(_3772);\n    }\n    else\n    {\n        _3777 = d;\n    }\n    return _3777;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3823 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 outc = vec3(0.0);\n    if (_3823 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[39].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3852 = rough * rough;\n            float _3883 = 0.60000002384185791015625 * _3852;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3852)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3883, 0.0500000007450580596923828125 + _3883, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3852 * 0.60000002384185791015625));\n        }\n        outc = base * _3823;\n    }\n    if (fa_mesh_fs_params[40].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[40];\n        vec4 param_5 = fa_mesh_fs_params[41];\n        vec4 param_6 = fa_mesh_fs_params[42];\n        vec4 param_7 = fa_mesh_fs_params[43];\n        vec4 param_8 = fa_mesh_fs_params[44];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3942 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3942 * fa_mesh_fs_params[40].w);\n    }\n    if (fa_mesh_fs_params[45].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[45];\n        vec4 param_12 = fa_mesh_fs_params[46];\n        vec4 param_13 = fa_mesh_fs_params[47];\n        vec4 param_14 = fa_mesh_fs_params[48];\n        vec4 param_15 = fa_mesh_fs_params[49];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3974 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3974 * fa_mesh_fs_params[45].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4620;\n        if (L.aniso >= 0.0)\n        {\n            _4620 = L.b;\n        }\n        else\n        {\n            _4620 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4620, v), _4620), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4653 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4653.x) + (vec3(L.f90) * _4653.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4708 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4708.x) + _4708.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4185 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4185.x) + vec3(_4185.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3205 = int(fa_shadows[25].x + 0.5);\n    float _3215 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3220 = _3205 > 0;\n    bool _3229;\n    if (_3220)\n    {\n        int param = _3205 - 1;\n        _3229 = _3215 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3229 = _3220;\n    }\n    if (_3229)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3235 = _3205 > 1;\n        bool _3242;\n        if (_3235)\n        {\n            _3242 = _3215 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3242 = _3235;\n        }\n        if (_3242)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3248 = _3205 > 2;\n        bool _3255;\n        if (_3248)\n        {\n            _3255 = _3215 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3255 = _3248;\n        }\n        if (_3255)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3261 = _3205 > 3;\n        bool _3268;\n        if (_3261)\n        {\n            _3268 = _3215 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3268 = _3261;\n        }\n        if (_3268)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7532 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7532 = -_7532;\n    }\n    vec3 _6895 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7532, fa_world_tangent, fa_uv, fa_vertex_color, _6895, gl_FrontFacing);\n    Surface _6903 = fa_standard_surface(param_1);\n    vec3 _7563 = _6903.albedo;\n    float _7564 = _6903.alpha;\n    vec3 _7565 = _6903.normal;\n    float _7566 = _6903.metallic;\n    float _7567 = _6903.roughness;\n    float _7568 = _6903.occlusion;\n    vec3 _7569 = _6903.emission;\n    float _7570 = _6903.clearcoat;\n    float _7571 = _6903.clearcoat_roughness;\n    vec3 _7572 = _6903.sheen_color;\n    float _7573 = _6903.sheen_roughness;\n    float _7574 = _6903.anisotropy;\n    float _7575 = _6903.anisotropy_rotation;\n    float _7576 = _6903.specular;\n    float _7577 = _6903.ior;\n    vec3 _7578 = _6903.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7532, fa_world_tangent, fa_uv, fa_vertex_color, _6895, gl_FrontFacing);\n    Surface param_3 = _6903;\n    surface(param_2, param_3);\n    _7563 = param_3.albedo;\n    _7564 = param_3.alpha;\n    _7565 = param_3.normal;\n    _7566 = param_3.metallic;\n    _7567 = param_3.roughness;\n    _7568 = param_3.occlusion;\n    _7569 = param_3.emission;\n    _7570 = param_3.clearcoat;\n    _7571 = param_3.clearcoat_roughness;\n    _7572 = param_3.sheen_color;\n    _7573 = param_3.sheen_roughness;\n    _7574 = param_3.anisotropy;\n    _7575 = param_3.anisotropy_rotation;\n    _7576 = param_3.specular;\n    _7577 = param_3.ior;\n    _7578 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7532;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7563 = param_6;\n    _7565 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7563;\n    }\n    else\n    {\n        vec3 _6942 = normalize(_7565);\n        float _6949 = clamp(_7566, 0.0, 1.0);\n        float _6953 = clamp(_7567, 0.0500000007450580596923828125, 1.0);\n        float _6957 = _6953 * _6953;\n        float _6961 = _6957 * _6957;\n        float _6966 = max(dot(_6942, _6895), 9.9999997473787516355514526367188e-05);\n        vec3 _6972 = _7563 * (1.0 - _6949);\n        vec3 _6979 = mix(vec3(0.039999999105930328369140625), _7563, vec3(_6949));\n        vec3 f0 = _6979;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7532, fa_world_tangent, fa_uv, fa_vertex_color, _6895, gl_FrontFacing);\n        Surface param_9 = Surface(_7563, _7564, _7565, _7566, _7567, _7568, _7569, _7570, _7571, _7572, _7573, _7574, _7575, _7576, _7577, _7578);\n        vec3 param_10 = _6942;\n        vec3 param_11 = _6895;\n        float param_12 = _6949;\n        float param_13 = _6953;\n        vec3 param_14 = _6979;\n        FaLayers _6995 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6942;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6972) * _7568;\n        if (_6995.on)\n        {\n            lit *= _6995.base_scale;\n        }\n        int _7017 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7017; ln++)\n        {\n            int param_16 = ln;\n            int _7030 = fa_cl_light(param_16);\n            int param_17 = _7030;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _7030;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7532;\n            LightSample _7046 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7054 = max(dot(_6942, _7046.direction), 0.0);\n            float _7060 = _7046.attenuation * _7046.shadow;\n            vec3 _7065 = normalize(_7046.direction + _6895);\n            float _7070 = max(dot(_6942, _7065), 0.0);\n            float _7075 = max(dot(_6895, _7065), 0.0);\n            bool _7082;\n            if (fa_light_is_area)\n            {\n                _7082 = !_6995.on;\n            }\n            else\n            {\n                _7082 = fa_light_is_area;\n            }\n            if (_7082)\n            {\n                int param_21 = _7030;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6942;\n                vec3 param_24 = _6895;\n                vec3 param_25 = _6972;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6953;\n                float param_29 = _6966;\n                float param_30 = _7060;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6995;\n                    int param_32 = _7030;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6942;\n                    vec3 param_35 = _6895;\n                    vec3 param_36 = _7046.direction;\n                    vec3 param_37 = _6972;\n                    vec3 param_38 = f0;\n                    float param_39 = _6953;\n                    float param_40 = _6966;\n                    float param_41 = _7060;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6995.on)\n                    {\n                        FaLayers param_42 = _6995;\n                        vec3 param_43 = _6972;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6942;\n                        vec3 param_46 = _6895;\n                        vec3 param_47 = _7046.direction;\n                        vec3 param_48 = _7065;\n                        float param_49 = _7054;\n                        float param_50 = _6966;\n                        float param_51 = _7070;\n                        float param_52 = _7075;\n                        float param_53 = _6957;\n                        float param_54 = _6961;\n                        int param_55 = _7030;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7060));\n                    }\n                    else\n                    {\n                        float _7188 = ((_7070 * _7070) * (_6961 - 1.0)) + 1.0;\n                        int param_56 = _7030;\n                        lit += (((_6972 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _7075, 5.0))) * (((_6961 / ((3.1415927410125732421875 * _7188) * _7188)) * (0.5 / max(mix((2.0 * _7054) * _6966, _7054 + _6966, _6957), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _7054))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7054 * _7060));\n                    }\n                }\n            }\n        }\n        if (_6995.on)\n        {\n            FaLayers param_57 = _6995;\n            vec3 param_58 = _6942;\n            vec3 param_59 = _6895;\n            vec3 param_60 = f0;\n            float param_61 = _6953;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7568);\n        }\n        else\n        {\n            vec3 param_62 = _6942;\n            vec3 param_63 = _6895;\n            vec3 param_64 = f0;\n            float param_65 = _6953;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7568);\n        }\n        result = lit;\n    }\n    vec3 _7283 = result;\n    vec3 _7284 = _7283 + _7569;\n    result = _7284;\n    vec3 param_66 = _7284;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _7293 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7300;\n    if (!_7293)\n    {\n        _7300 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7300 = _7293;\n    }\n    if (_7300)\n    {\n        vec3 _7309 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7315 = dot(_7309, fa_mesh_fs_params[9].xyz);\n        bool _7319 = fa_mesh_fs_params[9].w > 0.5;\n        float _7320;\n        if (_7319)\n        {\n            _7320 = _7315;\n        }\n        else\n        {\n            _7320 = length(_7309);\n        }\n        float _7332 = _7320 - fa_mesh_fs_params[8].x;\n        if (_7332 > 0.0)\n        {\n            float _7341 = fa_mesh_fs_params[7].w * _7332;\n            float tau = _7341 * _7341;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7357;\n                if (_7319)\n                {\n                    _7357 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7315);\n                }\n                else\n                {\n                    _7357 = fa_mesh_fs_params[0].y;\n                }\n                float _7378 = mix(_7357, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7320, 0.0, 1.0));\n                float _7382 = fa_world_pos.y - _7378;\n                float _7387 = _7378 - fa_mesh_fs_params[8].z;\n                float _7392 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7395 = _7387 <= 0.0;\n                bool _7396 = !_7395;\n                bool _7402;\n                if (_7396)\n                {\n                    _7402 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7402 = _7395;\n                }\n                float _7403;\n                if (_7402)\n                {\n                    _7403 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7403 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7387, 80.0));\n                }\n                bool _7430;\n                if (_7396)\n                {\n                    _7430 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7430 = _7395;\n                }\n                float _7431;\n                if (_7430)\n                {\n                    _7431 = fa_mesh_fs_params[8].y * _7387;\n                }\n                else\n                {\n                    _7431 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7387, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7456 = _7392 <= 0.0;\n                bool _7463;\n                if (!_7456)\n                {\n                    _7463 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7463 = _7456;\n                }\n                float _7464;\n                if (_7463)\n                {\n                    _7464 = fa_mesh_fs_params[8].y * _7392;\n                }\n                else\n                {\n                    _7464 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7392, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7491;\n                if (abs(_7382) < 0.001000000047497451305389404296875)\n                {\n                    _7491 = _7403;\n                }\n                else\n                {\n                    _7491 = (_7464 - _7431) / _7382;\n                }\n                tau += (_7332 * max(_7491, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _7564);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_602",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
            "inst_name": "_2269",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 11) in vec2 fa_attr_uv1;\nlayout(location = 12) in vec4 fa_attr_color1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\nvec4 vertex_color1;\nvec2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _186 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_186 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_186 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_186 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _88 = cross(model[1].xyz, model[2].xyz);\n    float _94 = (dot(model[0].xyz, _88) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_88 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _94, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _94), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(param_6.world_pos, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4285[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[50];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1540 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1547;\n    if (!_1540)\n    {\n        _1547 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1547 = _1540;\n    }\n    bool _1555;\n    if (!_1547)\n    {\n        _1555 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1555 = _1547;\n    }\n    bool _1562;\n    if (!_1555)\n    {\n        _1562 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1562 = _1555;\n    }\n    bool _1569;\n    if (!_1562)\n    {\n        _1569 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1569 = _1562;\n    }\n    if (_1569)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1579 = vec4(world_pos, 1.0);\n    float _1585 = dot(fa_mesh_fs_params[16], _1579);\n    if (!(_1585 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1607 = vec2(dot(fa_mesh_fs_params[14], _1579), dot(fa_mesh_fs_params[15], _1579)) / vec2(_1585);\n    int _1611 = int(fa_mesh_fs_params[18].x);\n    int _1615 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1615) + clamp(int(floor(((_1607.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1615 - 1)) * _1611)) + clamp(int(floor(((_1607.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1611 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1691 = fa_cluster_texel(param);\n    return ivec2(int(_1691.x), int(_1691.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5383 = fa_cluster_lookup(param);\n    fa_cl_slot = _5383.x;\n    fa_cl_local = _5383.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _6528 = fa_linear_to_srgb(param);\n        c = _6528;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _6536 = fa_srgb_to_linear(param_1);\n            c = _6536;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _484;\n    if (i.front_facing)\n    {\n        _484 = i.world_normal;\n    }\n    else\n    {\n        _484 = -i.world_normal;\n    }\n    vec3 _508 = normalize(i.world_tangent.xyz - (_484 * dot(_484, i.world_tangent.xyz)));\n    vec3 _535 = normalize(((_508 * m.x) + ((cross(_484, _508) * i.world_tangent.w) * m.y)) + (_484 * m.z));\n    vec3 _538;\n    if (i.front_facing)\n    {\n        _538 = _535;\n    }\n    else\n    {\n        _538 = -_535;\n    }\n    return _538;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _6567 = fa_tex_fix(param_2, param_3);\n    vec4 _8052 = base_t;\n    _8052.x = _6567.x;\n    _8052.y = _6567.y;\n    _8052.z = _6567.z;\n    base_t = _8052;\n    vec4 _6581 = (_8052 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _7852 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _6613 = fa_tex_fix(param_6, param_7);\n        vec3 _6616 = (_6613 * 2.0) - vec3(1.0);\n        vec2 _6621 = _6616.xy * fa_mesh_fs_params[6].x;\n        vec3 _8060 = _6616;\n        _8060.x = _6621.x;\n        _8060.y = _6621.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _8060;\n        _7852 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _6649 = fa_tex_fix(param_12, param_13);\n    vec4 _8063 = mrt;\n    _8063.x = _6649.x;\n    _8063.y = _6649.y;\n    _8063.z = _6649.z;\n    mrt = _8063;\n    vec4 _6677 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _6677.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _6688 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _6718 = fa_tex_fix(param_20, param_21);\n    float _7857 = fa_mesh_fs_params[20].x;\n    float _7858 = fa_mesh_fs_params[20].y;\n    float _7861 = fa_mesh_fs_params[20].z;\n    float _7860 = fa_mesh_fs_params[21].w;\n    float _7863 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _7857 *= _6688.y;\n            _7858 *= _6688.z;\n            _7860 *= _6677.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7861 *= mrt.x;\n            _7863 *= mrt.w;\n        }\n    }\n    return Surface(_6581.xyz, _6581.w, _7852, clamp(fa_mesh_fs_params[5].x * _6649.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _6649.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_6688.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _6718), _7857, _7858, fa_mesh_fs_params[21].xyz, _7860, _7861, fa_mesh_fs_params[20].w, _7863, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1771 = rect.zw - rect.xy;\n    vec2 _1775 = _1771 * atlas;\n    vec2 _1779 = ddx * _1775;\n    vec2 _1783 = ddy * _1775;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1771), clamp(0.5 * log2(max(max(dot(_1779, _1779), dot(_1783, _1783)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1816 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1823;\n    if (!_1816)\n    {\n        _1823 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1823 = _1816;\n    }\n    if (_1823)\n    {\n        return;\n    }\n    vec3 _1829 = dFdx(world_pos);\n    vec3 _1832 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1836 = fa_cluster_texel(param);\n    int _1840 = int(_1836.w);\n    if (_1840 < 1)\n    {\n        return;\n    }\n    int _1850 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1850;\n    vec4 _1854 = fa_light_texel(param_1);\n    vec2 _1857 = _1854.yz;\n    int _1861 = int(_1854.w);\n    int param_2 = _1850 + 1;\n    vec4 _1866 = fa_light_texel(param_2);\n    float _1867 = _1866.x;\n    int _1873 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1877 = int(_1836.z);\n    vec3 _2142;\n    for (int k = 0; k < _1840; k++)\n    {\n        int _1890 = _1877 + k;\n        int param_3 = _1861 + (_1890 >> 2);\n        int _1907 = (_1850 + 2) + (int(fa_light_texel(param_3)[_1890 & 3]) * 7);\n        int param_4 = _1907 + 6;\n        vec4 _1912 = fa_light_texel(param_4);\n        if (((int(_1912.w + 0.5) >> _1873) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1907;\n        vec4 _1927 = fa_light_texel(param_5);\n        int param_6 = _1907 + 1;\n        vec4 _1932 = fa_light_texel(param_6);\n        int param_7 = _1907 + 2;\n        vec4 _1937 = fa_light_texel(param_7);\n        vec3 _1940 = _1927.xyz;\n        float _1945 = dot(_1940, world_pos) + _1927.w;\n        vec3 _1947 = _1932.xyz;\n        float _1952 = dot(_1947, world_pos) + _1932.w;\n        vec3 _1954 = _1937.xyz;\n        float _1959 = dot(_1954, world_pos) + _1937.w;\n        bool _1964 = abs(_1945) > 0.5;\n        bool _1972;\n        if (!_1964)\n        {\n            _1972 = abs(_1952) > 0.5;\n        }\n        else\n        {\n            _1972 = _1964;\n        }\n        bool _1980;\n        if (!_1972)\n        {\n            _1980 = abs(_1959) > 0.5;\n        }\n        else\n        {\n            _1980 = _1972;\n        }\n        if (_1980)\n        {\n            continue;\n        }\n        float _1995 = clamp(dot(geo_normal, normalize(_1954)) * _1912.z, 0.0, 1.0);\n        if (_1995 <= 0.0)\n        {\n            continue;\n        }\n        float _2015 = (clamp((0.5 - abs(_1959)) * 10.0, 0.0, 1.0) * _1995) * _1912.x;\n        vec2 _2023 = vec2(_1945 + 0.5, 0.5 - _1952);\n        vec2 _2033 = vec2(dot(_1940, _1829), dot(_1947, _1829));\n        vec2 _2043 = vec2(dot(_1940, _1832), dot(_1947, _1832));\n        int param_8 = _1907 + 5;\n        vec4 _2048 = fa_light_texel(param_8);\n        int param_9 = _1907 + 3;\n        vec4 _2053 = fa_light_texel(param_9);\n        int param_10 = _1907 + 4;\n        vec4 _2058 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _2048.xyz;\n        bool _2068 = _2053.z > _2053.x;\n        if (_2068)\n        {\n            vec4 param_11 = _2053;\n            vec2 param_12 = _2023;\n            vec2 param_13 = _1857;\n            vec2 param_14 = _2033;\n            vec2 param_15 = _2043;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1867 > 0.5) && (_1867 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2094 = fa_dc_to_linear(param_16);\n                vec4 _7932 = tx;\n                _7932.x = _2094.x;\n                _7932.y = _2094.y;\n                _7932.z = _2094.z;\n                tx = _7932;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_2015 * tex_a) * _2048.w, 0.0, 1.0)));\n        if (_2058.z > _2058.x)\n        {\n            vec4 param_17 = _2058;\n            vec2 param_18 = _2023;\n            vec2 param_19 = _1857;\n            vec2 param_20 = _2033;\n            vec2 param_21 = _2043;\n            vec4 _2138 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1867 > 1.5)\n            {\n                vec3 param_22 = _2138.xyz;\n                vec3 _2148 = fa_dc_to_srgb(param_22);\n                _2142 = _2148;\n            }\n            else\n            {\n                _2142 = _2138.xyz;\n            }\n            vec3 _2157 = (_2142 * 2.0) - vec3(1.0);\n            vec2 _2162 = _2157.xy * _1912.y;\n            vec3 _2184 = (normalize(_1940) * _2162.x) + (normalize(_1947) * _2162.y);\n            vec3 _2187 = normalize(normal);\n            normal = normalize(mix(_2187, normalize((_2187 * max(_2157.z, 0.0500000007450580596923828125)) + (_2184 - (_2187 * dot(_2187, _2184)))), vec3(clamp(_2015 * (_2068 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4211 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4218 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4221 = int(_4211);\n    int _4224 = int(_4218);\n    float _4234 = _4218 - float(_4224);\n    int _4289 = (_4221 * 9) + _4224;\n    int _4309 = ((_4221 + 1) * 9) + _4224;\n    return mix(mix(_4285[_4289], _4285[_4289 + 1], _4234), mix(_4285[_4309], _4285[_4309 + 1], _4234), _4211 - float(_4221));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _7775 = false;\n    float _7776 = 1.0;\n    float _7777 = 1.0;\n    float _7778 = 1.0;\n    float _7779 = 0.0;\n    float _7780 = 0.0;\n    float _7781 = 0.0;\n    float _7782 = 0.0;\n    float _7784 = 1.0;\n    bool _7785 = false;\n    vec3 _7786 = vec3(0.0);\n    float _7787 = 1.0;\n    float _7788 = 1.0;\n    float _7789 = 1.0;\n    float _7790 = 0.0;\n    float _7791 = 0.0;\n    vec3 _7792 = vec3(1.0, 0.0, 0.0);\n    vec3 _7793 = vec3(0.0, 0.0, 1.0);\n    float _7794 = 1.0;\n    float _7795 = 1.0;\n    float _4360 = clamp(s.specular, 0.0, 1.0);\n    float _4364 = clamp(s.ior, 1.0, 3.0);\n    bool _4369 = (_4360 != 1.0) || (_4364 != 1.5);\n    bool _4378;\n    if (!_4369)\n    {\n        _4378 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4378 = _4369;\n    }\n    if (_4378)\n    {\n        float _4386 = (_4364 - 1.0) / (_4364 + 1.0);\n        f0 = mix(min(vec3(_4386 * _4386) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4360, s.albedo, vec3(metallic));\n        _7776 = mix(_4360, 1.0, metallic);\n        _7775 = true;\n    }\n    float _4413 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4413 > 0.0)\n    {\n        float _4421 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _7779 = _4413;\n        _7780 = _4421;\n        float _4428 = _4421 * _4421;\n        _7781 = _4428;\n        _7782 = _4428 * _4428;\n        float _4440 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _7784 = _4440;\n        _7777 = 1.0 - (_4413 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4440, 0.0, 1.0), 5.0))));\n        _7775 = true;\n    }\n    vec3 _4459 = max(s.sheen_color, vec3(0.0));\n    float _4468 = max(_4459.x, max(_4459.y, _4459.z));\n    if (_4468 > 0.0)\n    {\n        float _4476 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _7785 = true;\n        _7786 = _4459;\n        _7787 = _4476;\n        _7788 = _4476 * _4476;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4476;\n        float _4493 = fa_sheen_albedo(param, param_1);\n        _7790 = _4493;\n        _7789 = 1.0 - min(_4468 * _4493, 1.0);\n        _7775 = true;\n    }\n    _7778 = _7777 * _7789;\n    float _4512 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4512 != 0.0)\n    {\n        vec3 _4527 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4527;\n        if (dot(_4527, _4527) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4539 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4539.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4539.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4539.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4543 = t;\n        vec3 _4544 = normalize(_4543);\n        t = _4544;\n        vec3 _4569 = normalize((_4544 * cos(s.anisotropy_rotation)) + ((cross(n, _4544) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _7792 = _4569;\n        _7793 = cross(n, _4569);\n        float _4579 = roughness * roughness;\n        float _4585 = mix(_4579, 1.0, _4512 * _4512);\n        bool _4587 = _4512 > 0.0;\n        _7794 = _4587 ? _4585 : _4579;\n        _7795 = _4587 ? _4579 : _4585;\n        _7791 = _4512;\n        _7775 = true;\n    }\n    return FaLayers(_7775, _7776, _7777, _7778, _7779, _7780, _7781, _7782, i.world_normal, _7784, _7785, _7786, _7787, _7788, _7789, _7790, _7791, _7792, _7793, _7794, _7795);\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[39].y > 0.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3382 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3382;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3992 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 amb = vec3(0.0);\n    bool _3997 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3992 > 0.0005000000237487256526947021484375)\n    {\n        if (_3997)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[39].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3992;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3992;\n        }\n    }\n    bool _4048 = fa_mesh_fs_params[40].w > 0.0;\n    if (_4048)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[40].xy;\n            float param_4 = fa_mesh_fs_params[40].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[40].w);\n        }\n    }\n    bool _4079 = fa_mesh_fs_params[45].w > 0.0;\n    if (_4079)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[45].xy;\n            float param_7 = fa_mesh_fs_params[45].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[45].w);\n        }\n    }\n    if ((_3997 || _4048) || _4079)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5353;\n    if (fa_lm.z > 0.5)\n    {\n        _5353 = 0.0;\n    }\n    else\n    {\n        _5353 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _5364 = _5353 < 1.0;\n    bool _5370;\n    if (_5364)\n    {\n        int param = li;\n        _5370 = fa_light_baked(param);\n    }\n    else\n    {\n        _5370 = _5364;\n    }\n    return _5370 ? _5353 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _789 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _802 = (c - (ru * hx)) - p;\n        vec3 _808 = ru * (2.0 * hx);\n        float _814 = max(dot(_808, _808), 9.9999999392252902907785028219223e-09);\n        float _818 = dot(_802, _808);\n        float t = clamp((-_818) / _814, 0.0, 1.0);\n        if (_789)\n        {\n            float _833 = dot(r, _808);\n            float _839 = _814 - (_833 * _833);\n            if (abs(_839) > (9.9999997473787516355514526367188e-06 * _814))\n            {\n                t = clamp(((dot(r, _802) * _833) - _818) / _839, 0.0, 1.0);\n            }\n        }\n        return (p + _802) + (_808 * t);\n    }\n    vec3 q = p;\n    float _871 = dot(r, axis);\n    bool _879;\n    if (_789)\n    {\n        _879 = abs(_871) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _879 = _789;\n    }\n    if (_879)\n    {\n        float _889 = dot(c - p, axis) / _871;\n        if (_889 > 0.0)\n        {\n            q = p + (r * _889);\n        }\n    }\n    vec3 _902 = q - c;\n    vec2 xy = vec2(dot(_902, ru), dot(_902, uu));\n    if (shape > 0.5)\n    {\n        float _917 = length(xy);\n        if (_917 > hx)\n        {\n            xy *= (hx / _917);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _550 = abs(d);\n    float _552 = _550.x;\n    float _554 = _550.y;\n    bool _555 = _552 >= _554;\n    bool _563;\n    if (_555)\n    {\n        _563 = _552 >= _550.z;\n    }\n    else\n    {\n        _563 = _555;\n    }\n    int _564;\n    if (_563)\n    {\n        _564 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _579;\n        if (_554 >= _550.z)\n        {\n            _579 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _579 = (d.z > 0.0) ? 4 : 5;\n        }\n        _564 = _579;\n    }\n    return _564;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _709 = dot(d, right);\n    float _713 = dot(d, up);\n    float _724;\n    if (((_709 * _709) + (_713 * _713)) > 1.0000000133514319600180897396058e-10)\n    {\n        _724 = atan(_713, _709) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _724 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_724 - floor(_724)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _955 = fa_light_base(param);\n    bool _959 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _955;\n    vec4 _963 = fa_light_texel(param_1);\n    int param_2 = _955 + 1;\n    vec4 _968 = fa_light_texel(param_2);\n    float _971 = _968.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _983 = _959 && (_971 > 2.5);\n    fa_light_is_area = _983;\n    bool _985 = _971 < 0.5;\n    vec3 l;\n    if (_985)\n    {\n        l = normalize(_963.xyz);\n        if (_959)\n        {\n            int param_3 = _955 + 6;\n            vec4 _999 = fa_light_texel(param_3);\n            if (_999.z > 0.5)\n            {\n                int param_4 = _955 + 4;\n                vec4 _1009 = fa_light_texel(param_4);\n                int param_5 = _955 + 5;\n                vec4 _1014 = fa_light_texel(param_5);\n                vec2 param_6 = _999.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _1009.xyz) * _1009.w, (-dot(world_pos, _1014.xyz)) * _1014.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _1044 = _963.xyz;\n        vec3 _1046 = _1044 - world_pos;\n        vec3 to_light = _1046;\n        float _1049 = length(_1046);\n        float reach = _1049;\n        bool front = true;\n        if (_983)\n        {\n            int param_8 = _955 + 7;\n            reach = max(_1049 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _955 + 4;\n            vec4 _1073 = fa_light_texel(param_9);\n            int param_10 = _955 + 5;\n            vec4 _1078 = fa_light_texel(param_10);\n            int param_11 = _955 + 6;\n            vec4 _1083 = fa_light_texel(param_11);\n            float _1084 = _1083.w;\n            int param_12 = _955 + 2;\n            vec3 _1091 = normalize(fa_light_texel(param_12).xyz);\n            bool _1093 = _1084 > 1.5;\n            bool _1101;\n            if (!_1093)\n            {\n                _1101 = dot(_1091, to_light) < 0.0;\n            }\n            else\n            {\n                _1101 = _1093;\n            }\n            front = _1101;\n            vec3 r = vec3(0.0);\n            vec3 _1110 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1114 = dot(n, n) > 0.5;\n            bool _1122;\n            if (_1114)\n            {\n                _1122 = dot(_1110, _1110) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1122 = _1114;\n            }\n            if (_1122)\n            {\n                r = reflect(-normalize(_1110), normalize(n));\n            }\n            vec3 param_13 = _1044;\n            vec3 param_14 = _1091;\n            vec3 param_15 = _1073.xyz;\n            vec3 param_16 = _1078.xyz;\n            float param_17 = _1073.w;\n            float param_18 = _1078.w;\n            float param_19 = _1084;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1158 = length(to_light);\n        dist = _1158;\n        l = to_light / vec3(max(_1158, 9.9999997473787516355514526367188e-05));\n        float _1172 = reach / max(_963.w, 0.001000000047497451305389404296875);\n        float _1178 = clamp(1.0 - (_1172 * _1172), 0.0, 1.0);\n        float _1180;\n        if (front)\n        {\n            _1180 = _1178 * _1178;\n        }\n        else\n        {\n            _1180 = 0.0;\n        }\n        atten = _1180;\n        bool _1191 = _971 < 2.5;\n        if ((_971 > 1.5) && _1191)\n        {\n            int param_22 = _955 + 2;\n            vec4 _1199 = fa_light_texel(param_22);\n            float _1209 = _1199.w;\n            int param_23 = _955 + 3;\n            vec4 _1214 = fa_light_texel(param_23);\n            float _1215 = _1214.x;\n            float cos_inner = _1215;\n            if (_1215 > 1.5)\n            {\n                cos_inner = mix(_1209, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1209, cos_inner, dot(-l, normalize(_1199.xyz)));\n        }\n        if (_959 && (_971 < 1.5))\n        {\n            int param_24 = _955 + 6;\n            vec4 _1239 = fa_light_texel(param_24);\n            if (_1239.z > 0.5)\n            {\n                vec3 _1247 = -to_light;\n                int param_25 = _955 + 4;\n                int param_26 = _955 + 5;\n                vec3 _1261 = fa_light_texel(param_25).xyz;\n                vec3 _1265 = fa_light_texel(param_26).xyz;\n                vec3 _1274 = vec3(dot(_1247, _1261), dot(_1247, _1265), dot(_1247, cross(_1261, _1265)));\n                vec3 param_27 = _1274;\n                int _1278 = fa_cube_face(param_27);\n                int param_28 = _1278;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1305 = vec2(dot(_1274, cross(param_29, param_30)), dot(_1274, param_30)) / vec2(max(dot(_1274, param_29), 9.9999997473787516355514526367188e-05));\n                int _1309 = _1278 / 3;\n                vec2 param_31 = _1239.xy + (vec2(float(_1278 - (_1309 * 3)), float(_1309)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1305.x), 0.5 - (0.5 * _1305.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _955 + 7;\n            vec4 _1339 = fa_light_texel(param_33);\n            if (_1339.z > 0.5)\n            {\n                int param_34 = _955 + 2;\n                int param_35 = _955 + 4;\n                int param_36 = _955 + 5;\n                vec2 param_37 = _1339.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_959 && _1191)\n            {\n                int param_42 = _955 + 6;\n                vec4 _1386 = fa_light_texel(param_42);\n                int param_43 = _955 + 7;\n                vec4 _1391 = fa_light_texel(param_43);\n                bool _1394 = _1386.z > 0.5;\n                bool _1401;\n                if (!_1394)\n                {\n                    _1401 = _1391.z > 0.5;\n                }\n                else\n                {\n                    _1401 = _1394;\n                }\n                if (_1401)\n                {\n                    int param_44 = _955 + 2;\n                    vec4 _1408 = fa_light_texel(param_44);\n                    vec3 _1412 = normalize(_1408.xyz);\n                    int param_45 = _955 + 4;\n                    vec4 _1417 = fa_light_texel(param_45);\n                    int param_46 = _955 + 5;\n                    vec4 _1422 = fa_light_texel(param_46);\n                    if (_1394)\n                    {\n                        vec3 _1430 = -to_light;\n                        float _1437 = _1408.w;\n                        float _1453 = 0.5 / max(dot(_1430, _1412) * (sqrt(max(1.0 - (_1437 * _1437), 0.0)) / max(_1437, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1386.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1430, _1417.xyz) * _1453), 0.5 - (dot(_1430, _1422.xyz) * _1453));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1391.z > 0.5)\n                    {\n                        vec2 param_49 = _1391.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1412;\n                        vec3 param_52 = _1417.xyz;\n                        vec3 param_53 = _1422.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _7763 = _968.xyz * atten;\n    if (_959)\n    {\n        _7763 *= fa_light_tint;\n    }\n    int _1522;\n    if (_985)\n    {\n        _1522 = 0;\n    }\n    else\n    {\n        _1522 = ((_971 > 1.5) && (_971 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _7763, atten, 1.0, dist, _1522);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2259;\n    if (i == 0)\n    {\n        _2259 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2275;\n        if (i == 1)\n        {\n            _2275 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2283;\n            if (i == 2)\n            {\n                _2283 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2283 = fa_shadows[24].w;\n            }\n            _2275 = _2283;\n        }\n        _2259 = _2275;\n    }\n    return _2259;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2316 = fa_shadow_depth(param, param_1);\n    float _2320;\n    if (conv.x < 0.5)\n    {\n        _2320 = _2316;\n    }\n    else\n    {\n        _2320 = (conv.y * conv.z) / (conv.z - (_2316 * (conv.z - conv.y)));\n    }\n    return _2320;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2247 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2247), sin(_2247)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2366 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2375;\n        if (k < 0.0)\n        {\n            _2375 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2375 = k;\n        }\n        float _2395 = clamp((_2375 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2366;\n            vec2 _2414 = fa_shadow_vogel(param_3, param_4, param_5) * _2395;\n            vec2 param_6 = uv + (_2414 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2426 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2426 < (zr - (length(_2414) * plane)))\n            {\n                sum += _2426;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2452 = sum / cnt;\n        float _2462;\n        if (k < 0.0)\n        {\n            _2462 = (-k) / max(_2452, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2462 = k;\n        }\n        radius = clamp(((max(zr - _2452, 0.0) * unit) * _2462) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2484 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2484; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2484;\n        float param_11 = _2366;\n        vec2 _2503 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2503 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2503) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2484);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2545 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2550 = clamp(dot(n, l), 0.0, 1.0);\n    float _2556 = sqrt(1.0 - (_2550 * _2550));\n    float _2563 = min(_2556 / max(_2550, 0.20000000298023223876953125), 4.0);\n    float _2568;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2568 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2568 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2593 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2568 * _2556)), 1.0);\n    float _2600 = _2593.x;\n    bool _2603 = _2600 < fa_shadows[ci * 1 + 16].x;\n    bool _2612;\n    if (!_2603)\n    {\n        _2612 = _2600 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2612 = _2603;\n    }\n    bool _2621;\n    if (!_2612)\n    {\n        _2621 = _2593.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2621 = _2612;\n    }\n    bool _2630;\n    if (!_2621)\n    {\n        _2630 = _2593.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2630 = _2621;\n    }\n    bool _2637;\n    if (!_2630)\n    {\n        _2637 = _2593.z > 1.0;\n    }\n    else\n    {\n        _2637 = _2630;\n    }\n    if (_2637)\n    {\n        return -1.0;\n    }\n    float _2645;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2645 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2645 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2593.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2593.z - ((_2645 * (1.0 + (0.5 * _2563))) / _2545);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2545;\n    float param_5 = _2545 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2563, 3.0)) * 0.5) / _2545;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _3023 = int(fa_shadows[25].x + 0.5);\n    if (_3023 < 1)\n    {\n        return 1.0;\n    }\n    float _3038 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _3023 - 1;\n    if (_3038 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _3050 = _3023 > 1;\n    bool _3057;\n    if (_3050)\n    {\n        _3057 = _3038 > fa_shadows[24].x;\n    }\n    else\n    {\n        _3057 = _3050;\n    }\n    if (_3057)\n    {\n        ci = 1;\n    }\n    bool _3061 = _3023 > 2;\n    bool _3068;\n    if (_3061)\n    {\n        _3068 = _3038 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3068 = _3061;\n    }\n    if (_3068)\n    {\n        ci = 2;\n    }\n    bool _3072 = _3023 > 3;\n    bool _3079;\n    if (_3072)\n    {\n        _3079 = _3038 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3079 = _3072;\n    }\n    if (_3079)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _3023)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3105 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _3105;\n        if (_3105 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _3130;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _3130 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _3130 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _3149 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3130, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _3160 = clamp((_3038 - (fa_shadow_split_at(param_7) - _3149)) / _3149, 0.0, 1.0);\n        if (_3160 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _3023)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3181 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3181;\n                if (_3181 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _3160);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2703 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2710;\n    if (!_2703)\n    {\n        _2710 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2710 = _2703;\n    }\n    if (_2710)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2723 = fa_light_texel(param);\n    float _2724 = _2723.x;\n    if (_2724 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2733 = int(_2724 + 0.5);\n    int param_1 = _2733;\n    vec4 _2737 = fa_light_texel(param_1);\n    int param_2 = _2733 + 1;\n    vec4 _2742 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2745 = _2737.y;\n    if (_2745 > 0.0)\n    {\n        float _2762 = 1.0 - smoothstep(0.75 * _2745, _2745, length(world - fa_shadows[27].xyz));\n        fade = _2762;\n        if (_2762 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2737.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2786 = (_2733 + 2) + (face * 6);\n    int param_4 = _2786;\n    int param_5 = _2786 + 1;\n    int param_6 = _2786 + 3;\n    vec4 _2800 = fa_light_texel(param_6);\n    int param_7 = _2786 + 4;\n    vec4 _2805 = fa_light_texel(param_7);\n    int param_8 = _2786 + 5;\n    vec4 _2810 = fa_light_texel(param_8);\n    float _2822 = _2810.x * max(dot(_2800, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2827 = clamp(dot(n, l), 0.0, 1.0);\n    float _2850 = clamp(dot(n, _2800.xyz), -1.0, 1.0);\n    float _2869 = min(sqrt(1.0 - (_2850 * _2850)) / max(abs(dot(n, world - lpos)) / max(dot(_2800, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2872 = _2742.y;\n    float _2874;\n    if (_2872 > 0.0)\n    {\n        _2874 = _2872;\n    }\n    else\n    {\n        _2874 = 1.5 * _2822;\n    }\n    vec4 _2894 = vec4(world + (n * (_2874 * sqrt(1.0 - (_2827 * _2827)))), 1.0);\n    float _2898 = dot(_2800, _2894);\n    float _2901 = _2810.y;\n    if (_2898 < _2901)\n    {\n        return 1.0;\n    }\n    vec2 _2916 = vec2(dot(fa_light_texel(param_4), _2894), dot(fa_light_texel(param_5), _2894)) / vec2(_2898);\n    float _2918 = _2916.x;\n    bool _2921 = _2918 < _2805.x;\n    bool _2930;\n    if (!_2921)\n    {\n        _2930 = _2918 > _2805.z;\n    }\n    else\n    {\n        _2930 = _2921;\n    }\n    bool _2939;\n    if (!_2930)\n    {\n        _2939 = _2916.y < _2805.y;\n    }\n    else\n    {\n        _2939 = _2930;\n    }\n    bool _2948;\n    if (!_2939)\n    {\n        _2948 = _2916.y > _2805.w;\n    }\n    else\n    {\n        _2948 = _2939;\n    }\n    if (_2948)\n    {\n        return 1.0;\n    }\n    float _2954 = _2742.x;\n    float _2956;\n    if (_2954 > 0.0)\n    {\n        _2956 = _2954;\n    }\n    else\n    {\n        _2956 = 1.5 * _2822;\n    }\n    vec2 param_9 = _2916;\n    vec4 param_10 = _2805;\n    float param_11 = _2898 - (_2956 * (1.0 + (0.5 * _2869)));\n    float param_12 = _2822;\n    float param_13 = 1.0;\n    float param_14 = _2810.z * 0.25;\n    float param_15 = (_2822 * min(_2869, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2901, _2810.z);\n    int param_17 = int(_2737.z + 0.5);\n    float param_18 = _2737.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _5097 = fa_mesh_fs_params[24].x < 0.5;\n    bool _5104;\n    if (!_5097)\n    {\n        _5104 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _5104 = _5097;\n    }\n    if (_5104)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _5117 = fa_light_texel(param);\n    float _5118 = _5117.y;\n    float len = _5118;\n    if (_5118 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5130 = length(world - fa_mesh_fs_params[0].xyz);\n    float _5140 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _5130);\n    if (_5140 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _5146 = len;\n    float _5149 = min(_5146, 0.89999997615814208984375 * dist);\n    len = _5149;\n    float _5154 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _5130);\n    float _5159 = _5154 + (0.5 * _5149);\n    vec3 _5165 = world + (gn * _5154);\n    float _5167 = fa_shadow_noise();\n    float occ = 0.0;\n    float _5231;\n    for (int k = 0; k < 12; k++)\n    {\n        float _5182 = (float(k) + _5167) * 0.083333335816860198974609375;\n        vec3 _5190 = _5165 + (l * (_5182 * len));\n        vec4 _5196 = vec4(_5190, 1.0);\n        float _5202 = dot(fa_mesh_fs_params[28], _5196);\n        if (_5202 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _5222 = vec2(dot(fa_mesh_fs_params[26], _5196), dot(fa_mesh_fs_params[27], _5196)) / vec2(_5202);\n        float _5226 = _5222.x * 0.5;\n        float _5227 = _5226 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _5231 = (_5222.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _5231 = 0.5 - (_5222.y * 0.5);\n        }\n        bool _5247 = _5227 < 0.0;\n        bool _5254;\n        if (!_5247)\n        {\n            _5254 = _5227 >= 1.0;\n        }\n        else\n        {\n            _5254 = _5247;\n        }\n        bool _5261;\n        if (!_5254)\n        {\n            _5261 = _5231 < 0.0;\n        }\n        else\n        {\n            _5261 = _5254;\n        }\n        bool _5268;\n        if (!_5261)\n        {\n            _5268 = _5231 >= 1.0;\n        }\n        else\n        {\n            _5268 = _5261;\n        }\n        if (_5268)\n        {\n            break;\n        }\n        vec4 _5287 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_5227, _5231) * fa_mesh_fs_params[24].zw), 0);\n        if (_5287.w < 0.5)\n        {\n            continue;\n        }\n        float _5306 = (dot(fa_mesh_fs_params[29].xyz, _5190) + fa_mesh_fs_params[29].w) - _5287.x;\n        if ((_5306 > _5154) && (_5306 < _5159))\n        {\n            occ = max(occ, (1.0 - (_5182 * _5182)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_5227, 0.5 - _5226), min(_5231, 1.0 - _5231))));\n        }\n    }\n    return 1.0 - (occ * _5140);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5409 = fa_baked_keep(param);\n    if (_5409 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5435 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _7832 = _5435.color;\n    float _7833 = _5435.attenuation;\n    float _7834 = _5435.shadow;\n    bool _5438 = _5435.type == 0;\n    if (_5438 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5435.direction;\n        float _5449 = fa_shadow_factor(param_5, param_6);\n        _7834 = _5449;\n        _7832 *= _5449;\n    }\n    else\n    {\n        bool _5460 = _5435.type != 0;\n        bool _5466;\n        if (_5460)\n        {\n            _5466 = _7833 > 0.0;\n        }\n        else\n        {\n            _5466 = _5460;\n        }\n        if (_5466)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5435.direction;\n            float _5485 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _7834 = _5485;\n            _7832 *= _5485;\n        }\n    }\n    bool _5495 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5501;\n    if (_5495)\n    {\n        _5501 = _7833 > 0.0;\n    }\n    else\n    {\n        _5501 = _5495;\n    }\n    if (_5501)\n    {\n        float _5508;\n        if (_5438)\n        {\n            _5508 = 1000000000.0;\n        }\n        else\n        {\n            _5508 = _5435._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5435.direction;\n        float param_18 = _5508;\n        float _5526 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _7834 *= _5526;\n        _7832 *= _5526;\n    }\n    float _5539 = _7833;\n    float _5540 = _5539 * _5409;\n    _7833 = _5540;\n    vec3 _5544 = _7832;\n    vec3 _5545 = _5544 * _5409;\n    _7832 = _5545;\n    return LightSample(_5435.direction, _5545, _5540, _7834, _5435._distance, _5435.type);\n}\n\nvec3 fa_ltc_tangent(vec3 n, vec3 v)\n{\n    vec3 _5579 = v - (n * dot(v, n));\n    vec3 t = _5579;\n    float _5583 = dot(_5579, _5579);\n    float l2 = _5583;\n    if (_5583 < 1.0000000133514319600180897396058e-10)\n    {\n        vec3 _5593;\n        if (abs(n.z) < 0.999000012874603271484375)\n        {\n            _5593 = cross(n, vec3(0.0, 0.0, 1.0));\n        }\n        else\n        {\n            _5593 = cross(n, vec3(1.0, 0.0, 0.0));\n        }\n        t = _5593;\n        l2 = dot(_5593, _5593);\n    }\n    return t * inversesqrt(l2);\n}\n\nvec3 fa_ltc_local(vec3 t1, vec3 n, vec3 p)\n{\n    return vec3(dot(t1, p), dot(cross(n, t1), p), dot(n, p));\n}\n\nvec3 fa_ltc_edge_vector(vec3 a, vec3 b)\n{\n    float _5628 = dot(a, a);\n    float _5632 = dot(b, b);\n    if ((_5628 < 1.0000000195414813782625560981111e-24) || (_5632 < 1.0000000195414813782625560981111e-24))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5646 = a * inversesqrt(_5628);\n    vec3 _5651 = b * inversesqrt(_5632);\n    float _5655 = dot(_5646, _5651);\n    float _5658 = abs(_5655);\n    float g = (((((((((((0.0416471660137176513671875 * _5658) - 0.1924748718738555908203125) * _5658) + 0.4179156124591827392578125) * _5658) - 0.616057217121124267578125) * _5658) + 0.777722418308258056640625) * _5658) - 0.999542415142059326171875) * _5658) + 1.570791721343994140625;\n    if (_5655 < 0.0)\n    {\n        g = (3.1415927410125732421875 * inversesqrt(max(1.0 - (_5655 * _5655), 1.0000000116860974230803549289703e-07))) - g;\n    }\n    return cross(_5646, _5651) * g;\n}\n\nvoid fa_ltc_clip_edge(vec3 a, vec3 b, inout vec3 sum, inout vec3 leave, inout vec3 enter, inout vec2 seen)\n{\n    bool _5715 = a.z > 0.0;\n    bool _5719 = b.z > 0.0;\n    if (_5715 && _5719)\n    {\n        vec3 param = a;\n        vec3 param_1 = b;\n        sum += fa_ltc_edge_vector(param, param_1);\n    }\n    else\n    {\n        if (_5715 != _5719)\n        {\n            vec3 _5754 = a + ((b - a) * (a.z / (a.z - b.z)));\n            _5754.z = 0.0;\n            if (_5715)\n            {\n                vec3 param_2 = a;\n                vec3 param_3 = _5754;\n                sum += fa_ltc_edge_vector(param_2, param_3);\n                leave = _5754;\n                seen.x = 1.0;\n            }\n            else\n            {\n                vec3 param_4 = _5754;\n                vec3 param_5 = b;\n                sum += fa_ltc_edge_vector(param_4, param_5);\n                enter = _5754;\n                seen.y = 1.0;\n            }\n        }\n    }\n}\n\nfloat fa_ltc_quad(vec4 abcd, vec3 p0, vec3 p1, vec3 p2, vec3 p3)\n{\n    vec3 _5803 = vec3((abcd.x * p0.x) + (abcd.y * p0.z), p0.y, (abcd.z * p0.x) + (abcd.w * p0.z));\n    vec3 _5829 = vec3((abcd.x * p1.x) + (abcd.y * p1.z), p1.y, (abcd.z * p1.x) + (abcd.w * p1.z));\n    vec3 _5855 = vec3((abcd.x * p2.x) + (abcd.y * p2.z), p2.y, (abcd.z * p2.x) + (abcd.w * p2.z));\n    vec3 _5881 = vec3((abcd.x * p3.x) + (abcd.y * p3.z), p3.y, (abcd.z * p3.x) + (abcd.w * p3.z));\n    vec3 sum = vec3(0.0);\n    vec3 leave = vec3(0.0);\n    vec3 enter = vec3(0.0);\n    vec3 param = _5803;\n    vec3 param_1 = _5829;\n    vec3 param_2 = vec3(0.0);\n    vec3 param_3 = vec3(0.0);\n    vec3 param_4 = vec3(0.0);\n    vec2 param_5 = vec2(0.0);\n    fa_ltc_clip_edge(param, param_1, param_2, param_3, param_4, param_5);\n    sum = param_2;\n    leave = param_3;\n    enter = param_4;\n    vec3 param_6 = _5829;\n    vec3 param_7 = _5855;\n    vec3 param_8 = param_2;\n    vec3 param_9 = param_3;\n    vec3 param_10 = param_4;\n    vec2 param_11 = param_5;\n    fa_ltc_clip_edge(param_6, param_7, param_8, param_9, param_10, param_11);\n    sum = param_8;\n    leave = param_9;\n    enter = param_10;\n    vec3 param_12 = _5855;\n    vec3 param_13 = _5881;\n    vec3 param_14 = param_8;\n    vec3 param_15 = param_9;\n    vec3 param_16 = param_10;\n    vec2 param_17 = param_11;\n    fa_ltc_clip_edge(param_12, param_13, param_14, param_15, param_16, param_17);\n    sum = param_14;\n    leave = param_15;\n    enter = param_16;\n    vec3 param_18 = _5881;\n    vec3 param_19 = _5803;\n    vec3 param_20 = param_14;\n    vec3 param_21 = param_15;\n    vec3 param_22 = param_16;\n    vec2 param_23 = param_17;\n    fa_ltc_clip_edge(param_18, param_19, param_20, param_21, param_22, param_23);\n    sum = param_20;\n    leave = param_21;\n    enter = param_22;\n    if ((param_23.x * param_23.y) > 0.5)\n    {\n        vec3 param_24 = leave;\n        vec3 param_25 = enter;\n        sum += fa_ltc_edge_vector(param_24, param_25);\n    }\n    return sum.z * 0.15915493667125701904296875;\n}\n\nfloat fa_ltc_rect(vec4 abcd, vec3 center, vec3 ex, vec3 ey)\n{\n    vec4 param = abcd;\n    vec3 param_1 = (center - ex) - ey;\n    vec3 param_2 = (center + ex) - ey;\n    vec3 param_3 = (center + ex) + ey;\n    vec3 param_4 = (center - ex) + ey;\n    return abs(fa_ltc_quad(param, param_1, param_2, param_3, param_4));\n}\n\nfloat fa_area_form(vec4 m, float shape, vec3 pc, vec3 ex, vec3 ey)\n{\n    if ((shape < 0.5) || (shape > 1.5))\n    {\n        vec4 param = m;\n        vec3 param_1 = pc;\n        vec3 param_2 = ex;\n        vec3 param_3 = ey;\n        return fa_ltc_rect(param, param_1, param_2, param_3);\n    }\n    vec3 _6031 = (pc + (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6055 = (pc - (ex * 0.92387950420379638671875)) + (ey * 0.3826834261417388916015625);\n    vec3 _6071 = (pc - (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec4 param_4 = m;\n    vec3 param_5 = _6031;\n    vec3 param_6 = (pc + (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_7 = (pc - (ex * 0.3826834261417388916015625)) + (ey * 0.92387950420379638671875);\n    vec3 param_8 = _6055;\n    vec4 param_9 = m;\n    vec3 param_10 = _6031;\n    vec3 param_11 = _6055;\n    vec3 param_12 = (pc - (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    vec3 param_13 = _6071;\n    vec4 param_14 = m;\n    vec3 param_15 = _6031;\n    vec3 param_16 = _6071;\n    vec3 param_17 = (pc + (ex * 0.3826834261417388916015625)) - (ey * 0.92387950420379638671875);\n    vec3 param_18 = (pc + (ex * 0.92387950420379638671875)) - (ey * 0.3826834261417388916015625);\n    return abs((fa_ltc_quad(param_4, param_5, param_6, param_7, param_8) + fa_ltc_quad(param_9, param_10, param_11, param_12, param_13)) + fa_ltc_quad(param_14, param_15, param_16, param_17, param_18));\n}\n\nvec2 fa_ltc_uv(float roughness, float ndv)\n{\n    return ((vec2(clamp((roughness - 0.0500000007450580596923828125) * 1.0526316165924072265625, 0.0, 1.0), sqrt(clamp(1.0 - ndv, 0.0, 1.0))) * 63.0) + vec2(0.5)) * vec2(0.015625);\n}\n\nvec3 fa_area_shade(int li, vec3 world_pos, vec3 n, vec3 v, vec3 diffuse_color, vec3 f0, float f90, float roughness, float ndv, float window)\n{\n    int param = li;\n    int _6129 = fa_light_base(param);\n    int param_1 = _6129;\n    int param_2 = _6129 + 1;\n    int param_3 = _6129 + 2;\n    int param_4 = _6129 + 4;\n    vec4 _6151 = fa_light_texel(param_4);\n    int param_5 = _6129 + 5;\n    vec4 _6156 = fa_light_texel(param_5);\n    int param_6 = _6129 + 6;\n    vec4 _6161 = fa_light_texel(param_6);\n    float _6162 = _6161.w;\n    vec3 _6167 = fa_light_texel(param_1).xyz - world_pos;\n    bool _6169 = _6162 < 1.5;\n    bool _6176;\n    if (_6169)\n    {\n        _6176 = dot(normalize(fa_light_texel(param_3).xyz), _6167) >= 0.0;\n    }\n    else\n    {\n        _6176 = _6169;\n    }\n    if (_6176)\n    {\n        return vec3(0.0);\n    }\n    bool _6185 = (_6162 > 0.5) && _6169;\n    float _6189 = _6185 ? 1.0539000034332275390625 : 1.0;\n    vec3 _6192 = _6151.xyz;\n    float _6194 = _6151.w;\n    vec3 _6200 = _6156.xyz;\n    float _6202 = _6156.w;\n    vec3 up = _6200 * (_6202 * _6189);\n    float _6208;\n    if (_6185)\n    {\n        _6208 = (3.1415927410125732421875 * _6194) * _6194;\n    }\n    else\n    {\n        _6208 = (4.0 * _6194) * _6202;\n    }\n    if (_6162 > 1.5)\n    {\n        vec3 _6234 = cross(_6192, -_6167);\n        vec3 perp = _6234;\n        float _6238 = dot(_6234, _6234);\n        vec3 _6241;\n        if (_6238 > 1.0000000133514319600180897396058e-10)\n        {\n            _6241 = perp * inversesqrt(_6238);\n        }\n        else\n        {\n            _6241 = _6200;\n        }\n        perp = _6241;\n        up = _6241 * _6202;\n    }\n    float _6262 = max(_6208, 9.9999999747524270787835121154785e-07);\n    vec3 param_7 = n;\n    vec3 param_8 = v;\n    vec3 _6272 = fa_ltc_tangent(param_7, param_8);\n    vec3 param_9 = _6272;\n    vec3 param_10 = n;\n    vec3 param_11 = _6167;\n    vec3 _6280 = fa_ltc_local(param_9, param_10, param_11);\n    vec3 param_12 = _6272;\n    vec3 param_13 = n;\n    vec3 param_14 = _6192 * (_6194 * _6189);\n    vec3 _6288 = fa_ltc_local(param_12, param_13, param_14);\n    vec3 param_15 = _6272;\n    vec3 param_16 = n;\n    vec3 param_17 = up;\n    vec3 _6296 = fa_ltc_local(param_15, param_16, param_17);\n    vec4 param_18 = vec4(1.0, 0.0, 0.0, 1.0);\n    float param_19 = _6162;\n    vec3 param_20 = _6280;\n    vec3 param_21 = _6288;\n    vec3 param_22 = _6296;\n    float param_23 = roughness;\n    float param_24 = ndv;\n    vec2 _6315 = fa_ltc_uv(param_23, param_24) * 64.0;\n    vec2 param_25 = _6315;\n    vec2 param_26 = _6315 + vec2(64.0, 0.0);\n    vec4 _6325 = fa_atlas_fetch(param_26);\n    vec4 param_27 = fa_atlas_fetch(param_25);\n    float param_28 = _6162;\n    vec3 param_29 = _6280;\n    vec3 param_30 = _6288;\n    vec3 param_31 = _6296;\n    return (((diffuse_color * fa_area_form(param_18, param_19, param_20, param_21, param_22)) + (((f0 * _6325.x) + ((vec3(f90) - f0) * _6325.y)) * fa_area_form(param_27, param_28, param_29, param_30, param_31))) * fa_light_texel(param_2).xyz) * ((((3.1415927410125732421875 * dot(_6167, _6167)) + _6262) / _6262) * window);\n}\n\nvec3 fa_light_rgb(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).xyz;\n}\n\nfloat fa_d_charlie(float alpha, float ndh)\n{\n    float _4834 = 1.0 / alpha;\n    return ((2.0 + _4834) * pow(sqrt(max(1.0 - (ndh * ndh), 9.9999997473787516355514526367188e-05)), _4834)) * 0.15915493667125701904296875;\n}\n\nfloat fa_v_ashikhmin(float ndl, float ndv)\n{\n    return clamp(0.25 / max((ndl + ndv) - (ndl * ndv), 9.9999997473787516355514526367188e-05), 0.0, 1.0);\n}\n\nfloat fa_layers_coat(FaLayers L, vec3 l, vec3 h, float vdh)\n{\n    float _4869 = max(dot(L.nc, l), 0.0);\n    float _4875 = max(dot(L.nc, h), 0.0);\n    float _4884 = ((_4875 * _4875) * (L.coat_a2 - 1.0)) + 1.0;\n    return (((L.coat * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0)))) * (((L.coat_a2 / ((3.1415927410125732421875 * _4884) * _4884)) * (0.5 / max(mix((2.0 * _4869) * L.coat_ndv, _4869 + L.coat_ndv, L.coat_alpha), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _4869)) * _4869;\n}\n\nvec3 fa_area_layers(FaLayers L, int li, vec3 world_pos, vec3 n, vec3 v, vec3 l, vec3 diffuse_color, vec3 f0, float roughness, float ndv, float window)\n{\n    int param = li;\n    vec3 param_1 = world_pos;\n    vec3 param_2 = n;\n    vec3 param_3 = v;\n    vec3 param_4 = diffuse_color;\n    vec3 param_5 = f0;\n    float param_6 = L.f90;\n    float param_7 = roughness;\n    float param_8 = ndv;\n    float param_9 = window;\n    float _6393;\n    if (L.sheen_on)\n    {\n        _6393 = L.sheen_scale;\n    }\n    else\n    {\n        _6393 = 1.0;\n    }\n    vec3 result = fa_area_shade(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9) * (L.keep * _6393);\n    vec3 _6406 = normalize(l + v);\n    int param_10 = li;\n    vec3 _6417 = fa_light_rgb(param_10) * window;\n    if (L.sheen_on)\n    {\n        float _6426 = max(dot(n, l), 0.0);\n        float param_11 = L.sheen_alpha;\n        float param_12 = max(dot(n, _6406), 0.0);\n        float param_13 = _6426;\n        float param_14 = ndv;\n        result += ((L.sheen * _6417) * (((((fa_d_charlie(param_11, param_12) * fa_v_ashikhmin(param_13, param_14)) * 3.1415927410125732421875) * step(9.9999997473787516355514526367188e-05, _6426)) * _6426) * L.keep));\n    }\n    if (L.coat > 0.0)\n    {\n        FaLayers param_15 = L;\n        vec3 param_16 = l;\n        vec3 param_17 = _6406;\n        float param_18 = max(dot(v, _6406), 0.0);\n        result += (_6417 * fa_layers_coat(param_15, param_16, param_17, param_18));\n    }\n    return result;\n}\n\nfloat fa_d_ggx_aniso(float ndh, float tdh, float bdh, float at, float ab)\n{\n    float _4737 = tdh / at;\n    float _4741 = bdh / ab;\n    float _4753 = ((_4737 * _4737) + (_4741 * _4741)) + (ndh * ndh);\n    return 1.0 / ((((3.1415927410125732421875 * at) * ab) * _4753) * _4753);\n}\n\nfloat fa_lambda_ggx_aniso(float n, float t, float b, float at, float ab)\n{\n    return 0.5 * (sqrt(1.0 + (((((at * at) * t) * t) + (((ab * ab) * b) * b)) / max(n * n, 9.9999999392252902907785028219223e-09))) - 1.0);\n}\n\nfloat fa_v_ggx_aniso(float ndl, float ndv, float tdv, float bdv, float tdl, float bdl, float at, float ab)\n{\n    float param = ndv;\n    float param_1 = tdv;\n    float param_2 = bdv;\n    float param_3 = at;\n    float param_4 = ab;\n    float param_5 = ndl;\n    float param_6 = tdl;\n    float param_7 = bdl;\n    float param_8 = at;\n    float param_9 = ab;\n    return clamp(1.0 / ((4.0 * max(ndl * ndv, 9.9999997473787516355514526367188e-05)) * ((1.0 + fa_lambda_ggx_aniso(param, param_1, param_2, param_3, param_4)) + fa_lambda_ggx_aniso(param_5, param_6, param_7, param_8, param_9))), 0.0, 1.0);\n}\n\nvec3 fa_layers_light(FaLayers L, vec3 diffuse_color, vec3 f0, vec3 n, vec3 v, vec3 l, vec3 h, float ndl, float ndv, float ndh, float vdh, float alpha, float a2)\n{\n    float _4933 = step(9.9999997473787516355514526367188e-05, ndl);\n    float d_ggx;\n    float vis;\n    if (L.aniso != 0.0)\n    {\n        float param = ndh;\n        float param_1 = dot(L.t, h);\n        float param_2 = dot(L.b, h);\n        float param_3 = L.at;\n        float param_4 = L.ab;\n        d_ggx = fa_d_ggx_aniso(param, param_1, param_2, param_3, param_4);\n        float param_5 = ndl;\n        float param_6 = ndv;\n        float param_7 = dot(L.t, v);\n        float param_8 = dot(L.b, v);\n        float param_9 = dot(L.t, l);\n        float param_10 = dot(L.b, l);\n        float param_11 = L.at;\n        float param_12 = L.ab;\n        vis = fa_v_ggx_aniso(param_5, param_6, param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    else\n    {\n        float _5012 = ((ndh * ndh) * (a2 - 1.0)) + 1.0;\n        d_ggx = a2 / ((3.1415927410125732421875 * _5012) * _5012);\n        vis = 0.5 / max(mix((2.0 * ndl) * ndv, ndl + ndv, alpha), 9.9999997473787516355514526367188e-05);\n    }\n    vec3 base = diffuse_color + (((f0 + ((vec3(L.f90) - f0) * pow(clamp(1.0 - vdh, 0.0, 1.0), 5.0))) * ((d_ggx * vis) * 3.1415927410125732421875)) * _4933);\n    if (L.sheen_on)\n    {\n        float param_13 = L.sheen_alpha;\n        float param_14 = ndh;\n        float param_15 = ndl;\n        float param_16 = ndv;\n        base = (base * L.sheen_scale) + (L.sheen * (((fa_d_charlie(param_13, param_14) * fa_v_ashikhmin(param_15, param_16)) * 3.1415927410125732421875) * _4933));\n    }\n    vec3 result = base * (L.keep * ndl);\n    if (L.coat > 0.0)\n    {\n        FaLayers param_17 = L;\n        vec3 param_18 = l;\n        vec3 param_19 = h;\n        float param_20 = vdh;\n        result += vec3(fa_layers_coat(param_17, param_18, param_19, param_20));\n    }\n    return result;\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4143 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4146 = _4143.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4146 * _4146, exp2((-9.27999973297119140625) * ndv)) * _4146) + _4143.y)) + _4143.zw;\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3402 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3405 = _3402.x;\n    float _3407 = _3402.z;\n    vec2 e = vec2(_3405, _3407);\n    if (_3402.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3407)) * ((_3405 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3405)) * ((_3407 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3454;\n    if (lv == 0)\n    {\n        _3454 = 0.0;\n    }\n    else\n    {\n        _3454 = res + 2.0;\n    }\n    float _3464;\n    if (lv == 0)\n    {\n        _3464 = 0.0;\n    }\n    else\n    {\n        _3464 = (res - (res / float(1 << (lv - 1)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3454, _3464)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3509;\n    if (res > 64.5)\n    {\n        _3509 = 5.0;\n    }\n    else\n    {\n        _3509 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3524 = clamp(rough, 0.0, 1.0) * (_3509 - 1.0);\n    int _3531 = int(min(floor(_3524), _3509 - 2.0));\n    float _3536 = _3524 - float(_3531);\n    vec3 param = d;\n    vec2 _3540 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3531;\n    vec2 param_4 = _3540;\n    vec3 _3550 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3536 < 0.00200000009499490261077880859375)\n    {\n        return _3550;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3531 + 1;\n    vec2 param_8 = _3540;\n    return mix(_3550, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3536));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3620 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3627 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3634 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3640 = dot(bx.xyz, d);\n    float _3644 = dot(by.xyz, d);\n    float _3648 = dot(bz.xyz, d);\n    float _3654;\n    if (_3640 > 9.9999999747524270787835121154785e-07)\n    {\n        _3654 = (1.0 - _3620) / _3640;\n    }\n    else\n    {\n        float _3668;\n        if (_3640 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3668 = ((-1.0) - _3620) / _3640;\n        }\n        else\n        {\n            _3668 = 1000000015047466219876688855040.0;\n        }\n        _3654 = _3668;\n    }\n    float tx = _3654;\n    float _3685;\n    if (_3644 > 9.9999999747524270787835121154785e-07)\n    {\n        _3685 = (1.0 - _3627) / _3644;\n    }\n    else\n    {\n        float _3698;\n        if (_3644 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3698 = ((-1.0) - _3627) / _3644;\n        }\n        else\n        {\n            _3698 = 1000000015047466219876688855040.0;\n        }\n        _3685 = _3698;\n    }\n    float ty = _3685;\n    float _3714;\n    if (_3648 > 9.9999999747524270787835121154785e-07)\n    {\n        _3714 = (1.0 - _3634) / _3648;\n    }\n    else\n    {\n        float _3727;\n        if (_3648 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3727 = ((-1.0) - _3634) / _3648;\n        }\n        else\n        {\n            _3727 = 1000000015047466219876688855040.0;\n        }\n        _3714 = _3727;\n    }\n    float _3739 = tx;\n    float _3742 = (_3739 > 0.0) ? _3739 : 1000000015047466219876688855040.0;\n    tx = _3742;\n    float _3743 = ty;\n    float _3746 = (_3743 > 0.0) ? _3743 : 1000000015047466219876688855040.0;\n    ty = _3746;\n    float _3756 = min(_3742, min(_3746, (_3714 > 0.0) ? _3714 : 1000000015047466219876688855040.0));\n    if (_3756 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3772 = (fa_world_pos + (d * _3756)) - posw.xyz;\n    vec3 _3777;\n    if (dot(_3772, _3772) > 1.0000000133514319600180897396058e-10)\n    {\n        _3777 = normalize(_3772);\n    }\n    else\n    {\n        _3777 = d;\n    }\n    return _3777;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3823 = (1.0 - fa_mesh_fs_params[40].w) - fa_mesh_fs_params[45].w;\n    vec3 outc = vec3(0.0);\n    if (_3823 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[39].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3852 = rough * rough;\n            float _3883 = 0.60000002384185791015625 * _3852;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3852)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3883, 0.0500000007450580596923828125 + _3883, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3852 * 0.60000002384185791015625));\n        }\n        outc = base * _3823;\n    }\n    if (fa_mesh_fs_params[40].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[40];\n        vec4 param_5 = fa_mesh_fs_params[41];\n        vec4 param_6 = fa_mesh_fs_params[42];\n        vec4 param_7 = fa_mesh_fs_params[43];\n        vec4 param_8 = fa_mesh_fs_params[44];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3942 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3942 * fa_mesh_fs_params[40].w);\n    }\n    if (fa_mesh_fs_params[45].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[45];\n        vec4 param_12 = fa_mesh_fs_params[46];\n        vec4 param_13 = fa_mesh_fs_params[47];\n        vec4 param_14 = fa_mesh_fs_params[48];\n        vec4 param_15 = fa_mesh_fs_params[49];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3974 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3974 * fa_mesh_fs_params[45].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4620;\n        if (L.aniso >= 0.0)\n        {\n            _4620 = L.b;\n        }\n        else\n        {\n            _4620 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4620, v), _4620), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4653 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4653.x) + (vec3(L.f90) * _4653.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4708 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4708.x) + _4708.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4185 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4185.x) + vec3(_4185.y));\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3205 = int(fa_shadows[25].x + 0.5);\n    float _3215 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3220 = _3205 > 0;\n    bool _3229;\n    if (_3220)\n    {\n        int param = _3205 - 1;\n        _3229 = _3215 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3229 = _3220;\n    }\n    if (_3229)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3235 = _3205 > 1;\n        bool _3242;\n        if (_3235)\n        {\n            _3242 = _3215 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3242 = _3235;\n        }\n        if (_3242)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3248 = _3205 > 2;\n        bool _3255;\n        if (_3248)\n        {\n            _3255 = _3215 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3255 = _3248;\n        }\n        if (_3255)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3261 = _3205 > 3;\n        bool _3268;\n        if (_3261)\n        {\n            _3268 = _3215 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3268 = _3261;\n        }\n        if (_3268)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _7532 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _7532 = -_7532;\n    }\n    vec3 _6895 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _7532, fa_world_tangent, fa_uv, fa_vertex_color, _6895, gl_FrontFacing);\n    Surface _6903 = fa_standard_surface(param_1);\n    vec3 _7563 = _6903.albedo;\n    float _7564 = _6903.alpha;\n    vec3 _7565 = _6903.normal;\n    float _7566 = _6903.metallic;\n    float _7567 = _6903.roughness;\n    float _7568 = _6903.occlusion;\n    vec3 _7569 = _6903.emission;\n    float _7570 = _6903.clearcoat;\n    float _7571 = _6903.clearcoat_roughness;\n    vec3 _7572 = _6903.sheen_color;\n    float _7573 = _6903.sheen_roughness;\n    float _7574 = _6903.anisotropy;\n    float _7575 = _6903.anisotropy_rotation;\n    float _7576 = _6903.specular;\n    float _7577 = _6903.ior;\n    vec3 _7578 = _6903.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _7532, fa_world_tangent, fa_uv, fa_vertex_color, _6895, gl_FrontFacing);\n    Surface param_3 = _6903;\n    surface(param_2, param_3);\n    _7563 = param_3.albedo;\n    _7564 = param_3.alpha;\n    _7565 = param_3.normal;\n    _7566 = param_3.metallic;\n    _7567 = param_3.roughness;\n    _7568 = param_3.occlusion;\n    _7569 = param_3.emission;\n    _7570 = param_3.clearcoat;\n    _7571 = param_3.clearcoat_roughness;\n    _7572 = param_3.sheen_color;\n    _7573 = param_3.sheen_roughness;\n    _7574 = param_3.anisotropy;\n    _7575 = param_3.anisotropy_rotation;\n    _7576 = param_3.specular;\n    _7577 = param_3.ior;\n    _7578 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _7532;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _7563 = param_6;\n    _7565 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _7563;\n    }\n    else\n    {\n        vec3 _6942 = normalize(_7565);\n        float _6949 = clamp(_7566, 0.0, 1.0);\n        float _6953 = clamp(_7567, 0.0500000007450580596923828125, 1.0);\n        float _6957 = _6953 * _6953;\n        float _6961 = _6957 * _6957;\n        float _6966 = max(dot(_6942, _6895), 9.9999997473787516355514526367188e-05);\n        vec3 _6972 = _7563 * (1.0 - _6949);\n        vec3 _6979 = mix(vec3(0.039999999105930328369140625), _7563, vec3(_6949));\n        vec3 f0 = _6979;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _7532, fa_world_tangent, fa_uv, fa_vertex_color, _6895, gl_FrontFacing);\n        Surface param_9 = Surface(_7563, _7564, _7565, _7566, _7567, _7568, _7569, _7570, _7571, _7572, _7573, _7574, _7575, _7576, _7577, _7578);\n        vec3 param_10 = _6942;\n        vec3 param_11 = _6895;\n        float param_12 = _6949;\n        float param_13 = _6953;\n        vec3 param_14 = _6979;\n        FaLayers _6995 = fa_layers_setup(param_8, param_9, param_10, param_11, param_12, param_13, param_14);\n        f0 = param_14;\n        vec3 param_15 = _6942;\n        vec3 lit = (fa_indirect_diffuse(param_15) * _6972) * _7568;\n        if (_6995.on)\n        {\n            lit *= _6995.base_scale;\n        }\n        int _7017 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _7017; ln++)\n        {\n            int param_16 = ln;\n            int _7030 = fa_cl_light(param_16);\n            int param_17 = _7030;\n            if (fa_baked_keep(param_17) <= 0.0)\n            {\n                continue;\n            }\n            int param_18 = _7030;\n            vec3 param_19 = fa_world_pos;\n            vec3 param_20 = _7532;\n            LightSample _7046 = fa_light_shadowed(param_18, param_19, param_20);\n            float _7054 = max(dot(_6942, _7046.direction), 0.0);\n            float _7060 = _7046.attenuation * _7046.shadow;\n            vec3 _7065 = normalize(_7046.direction + _6895);\n            float _7070 = max(dot(_6942, _7065), 0.0);\n            float _7075 = max(dot(_6895, _7065), 0.0);\n            bool _7082;\n            if (fa_light_is_area)\n            {\n                _7082 = !_6995.on;\n            }\n            else\n            {\n                _7082 = fa_light_is_area;\n            }\n            if (_7082)\n            {\n                int param_21 = _7030;\n                vec3 param_22 = fa_world_pos;\n                vec3 param_23 = _6942;\n                vec3 param_24 = _6895;\n                vec3 param_25 = _6972;\n                vec3 param_26 = f0;\n                float param_27 = 1.0;\n                float param_28 = _6953;\n                float param_29 = _6966;\n                float param_30 = _7060;\n                lit += fa_area_shade(param_21, param_22, param_23, param_24, param_25, param_26, param_27, param_28, param_29, param_30);\n            }\n            else\n            {\n                if (fa_light_is_area)\n                {\n                    FaLayers param_31 = _6995;\n                    int param_32 = _7030;\n                    vec3 param_33 = fa_world_pos;\n                    vec3 param_34 = _6942;\n                    vec3 param_35 = _6895;\n                    vec3 param_36 = _7046.direction;\n                    vec3 param_37 = _6972;\n                    vec3 param_38 = f0;\n                    float param_39 = _6953;\n                    float param_40 = _6966;\n                    float param_41 = _7060;\n                    lit += fa_area_layers(param_31, param_32, param_33, param_34, param_35, param_36, param_37, param_38, param_39, param_40, param_41);\n                }\n                else\n                {\n                    if (_6995.on)\n                    {\n                        FaLayers param_42 = _6995;\n                        vec3 param_43 = _6972;\n                        vec3 param_44 = f0;\n                        vec3 param_45 = _6942;\n                        vec3 param_46 = _6895;\n                        vec3 param_47 = _7046.direction;\n                        vec3 param_48 = _7065;\n                        float param_49 = _7054;\n                        float param_50 = _6966;\n                        float param_51 = _7070;\n                        float param_52 = _7075;\n                        float param_53 = _6957;\n                        float param_54 = _6961;\n                        int param_55 = _7030;\n                        lit += (fa_layers_light(param_42, param_43, param_44, param_45, param_46, param_47, param_48, param_49, param_50, param_51, param_52, param_53, param_54) * ((fa_light_rgb(param_55) * fa_light_tint) * _7060));\n                    }\n                    else\n                    {\n                        float _7188 = ((_7070 * _7070) * (_6961 - 1.0)) + 1.0;\n                        int param_56 = _7030;\n                        lit += (((_6972 + (((f0 + ((vec3(1.0) - f0) * pow(1.0 - _7075, 5.0))) * (((_6961 / ((3.1415927410125732421875 * _7188) * _7188)) * (0.5 / max(mix((2.0 * _7054) * _6966, _7054 + _6966, _6957), 9.9999997473787516355514526367188e-05))) * 3.1415927410125732421875)) * step(9.9999997473787516355514526367188e-05, _7054))) * (fa_light_rgb(param_56) * fa_light_tint)) * (_7054 * _7060));\n                    }\n                }\n            }\n        }\n        if (_6995.on)\n        {\n            FaLayers param_57 = _6995;\n            vec3 param_58 = _6942;\n            vec3 param_59 = _6895;\n            vec3 param_60 = f0;\n            float param_61 = _6953;\n            lit += (fa_layers_ibl(param_57, param_58, param_59, param_60, param_61) * _7568);\n        }\n        else\n        {\n            vec3 param_62 = _6942;\n            vec3 param_63 = _6895;\n            vec3 param_64 = f0;\n            float param_65 = _6953;\n            lit += (fa_sky_reflection(param_62, param_63, param_64, param_65) * _7568);\n        }\n        result = lit;\n    }\n    vec3 _7283 = result;\n    vec3 _7284 = _7283 + _7569;\n    result = _7284;\n    vec3 param_66 = _7284;\n    vec3 param_67 = fa_world_pos;\n    result = fa_shadow_debug(param_66, param_67);\n    bool _7293 = fa_mesh_fs_params[7].w > 0.0;\n    bool _7300;\n    if (!_7293)\n    {\n        _7300 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _7300 = _7293;\n    }\n    if (_7300)\n    {\n        vec3 _7309 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _7315 = dot(_7309, fa_mesh_fs_params[9].xyz);\n        bool _7319 = fa_mesh_fs_params[9].w > 0.5;\n        float _7320;\n        if (_7319)\n        {\n            _7320 = _7315;\n        }\n        else\n        {\n            _7320 = length(_7309);\n        }\n        float _7332 = _7320 - fa_mesh_fs_params[8].x;\n        if (_7332 > 0.0)\n        {\n            float _7341 = fa_mesh_fs_params[7].w * _7332;\n            float tau = _7341 * _7341;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _7357;\n                if (_7319)\n                {\n                    _7357 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _7315);\n                }\n                else\n                {\n                    _7357 = fa_mesh_fs_params[0].y;\n                }\n                float _7378 = mix(_7357, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _7320, 0.0, 1.0));\n                float _7382 = fa_world_pos.y - _7378;\n                float _7387 = _7378 - fa_mesh_fs_params[8].z;\n                float _7392 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _7395 = _7387 <= 0.0;\n                bool _7396 = !_7395;\n                bool _7402;\n                if (_7396)\n                {\n                    _7402 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7402 = _7395;\n                }\n                float _7403;\n                if (_7402)\n                {\n                    _7403 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _7403 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _7387, 80.0));\n                }\n                bool _7430;\n                if (_7396)\n                {\n                    _7430 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7430 = _7395;\n                }\n                float _7431;\n                if (_7430)\n                {\n                    _7431 = fa_mesh_fs_params[8].y * _7387;\n                }\n                else\n                {\n                    _7431 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7387, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _7456 = _7392 <= 0.0;\n                bool _7463;\n                if (!_7456)\n                {\n                    _7463 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _7463 = _7456;\n                }\n                float _7464;\n                if (_7463)\n                {\n                    _7464 = fa_mesh_fs_params[8].y * _7392;\n                }\n                else\n                {\n                    _7464 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _7392, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _7491;\n                if (abs(_7382) < 0.001000000047497451305389404296875)\n                {\n                    _7491 = _7403;\n                }\n                else\n                {\n                    _7491 = (_7464 - _7431) / _7382;\n                }\n                tau += (_7332 * max(_7491, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _7564);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_602",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
            "inst_name": "_2269",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 9) in vec2 fa_attr_uv1;\nlayout(location = 10) in vec4 fa_attr_color1;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nvec4 vertex_color1;\nvec2 vertex_uv1;\n\nvoid fa_inst_begin()\n{\n    vertex_uv1 = fa_attr_uv1;\n    vertex_color1 = fa_attr_color1;\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _83 = cross(model[1].xyz, model[2].xyz);\n    float _89 = (dot(model[0].xyz, _83) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_83 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _89, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _89), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid vertex(inout VertexData v)\n{\n    v.color = vertex_color1;\n    v.uv = vertex_uv1;\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData param_6 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vertex(param_6);\n    mat4 _180 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _187 = vec4(param_6.world_pos, 1.0);\n    fa_world_pos = param_6.world_pos;\n    fa_world_normal = param_6.world_normal;\n    fa_world_tangent = param_6.world_tangent;\n    fa_uv = param_6.uv;\n    fa_vertex_color = param_6.color;\n    fa_pre_depth = -(_180 * _187).z;\n    fa_pre_r0 = vec3(_180[0].x, _180[1].x, _180[2].x);\n    fa_pre_r1 = vec3(_180[0].y, _180[1].y, _180[2].y);\n    fa_pre_r2 = vec3(_180[0].z, _180[1].z, _180[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _187;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _240 = fa_tex_fix(param_2, param_3);\n    vec4 _746 = base_t;\n    _746.x = _240.x;\n    _746.y = _240.y;\n    _746.z = _240.z;\n    base_t = _746;\n    vec4 _255 = (_746 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _709 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _289 = fa_tex_fix(param_6, param_7);\n        vec3 _292 = (_289 * 2.0) - vec3(1.0);\n        vec2 _297 = _292.xy * fa_mesh_fs_params[6].x;\n        vec3 _754 = _292;\n        _754.x = _297.x;\n        _754.y = _297.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _754;\n        _709 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _326 = fa_tex_fix(param_12, param_13);\n    vec4 _757 = mrt;\n    _757.x = _326.x;\n    _757.y = _326.y;\n    _757.z = _326.z;\n    mrt = _757;\n    vec4 _356 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _714 = fa_mesh_fs_params[20].x;\n    float _715 = fa_mesh_fs_params[20].y;\n    float _718 = fa_mesh_fs_params[20].z;\n    float _717 = fa_mesh_fs_params[21].w;\n    float _720 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _714 *= _368.y;\n            _715 *= _368.z;\n            _717 *= _356.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _718 *= mrt.x;\n            _720 *= mrt.w;\n        }\n    }\n    return Surface(_255.xyz, _255.w, _709, clamp(fa_mesh_fs_params[5].x * _326.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_368.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _714, _715, fa_mesh_fs_params[21].xyz, _717, _718, fa_mesh_fs_params[20].w, _720, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _620 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _620 = -_620;\n    }\n    vec3 _532 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _620, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _620, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _547 = normalize(param_2.normal);\n    vec3 _562 = normalize(vec3(dot(fa_pre_r0, _547), dot(fa_pre_r1, _547), dot(fa_pre_r2, _547)));\n    float _574 = _562.z;\n    vec2 e = _562.xy / vec2((abs(_562.x) + abs(_562.y)) + abs(_574));\n    if (_574 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_228",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[50];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _186 = fa_linear_to_srgb(param);\n        c = _186;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _195 = fa_srgb_to_linear(param_1);\n            c = _195;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _240 = fa_tex_fix(param_2, param_3);\n    vec4 _746 = base_t;\n    _746.x = _240.x;\n    _746.y = _240.y;\n    _746.z = _240.z;\n    base_t = _746;\n    vec4 _255 = (_746 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _709 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _289 = fa_tex_fix(param_6, param_7);\n        vec3 _292 = (_289 * 2.0) - vec3(1.0);\n        vec2 _297 = _292.xy * fa_mesh_fs_params[6].x;\n        vec3 _754 = _292;\n        _754.x = _297.x;\n        _754.y = _297.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _754;\n        _709 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _326 = fa_tex_fix(param_12, param_13);\n    vec4 _757 = mrt;\n    _757.x = _326.x;\n    _757.y = _326.y;\n    _757.z = _326.z;\n    mrt = _757;\n    vec4 _356 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _356.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _368 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _398 = fa_tex_fix(param_20, param_21);\n    float _714 = fa_mesh_fs_params[20].x;\n    float _715 = fa_mesh_fs_params[20].y;\n    float _718 = fa_mesh_fs_params[20].z;\n    float _717 = fa_mesh_fs_params[21].w;\n    float _720 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _714 *= _368.y;\n            _715 *= _368.z;\n            _717 *= _356.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _718 *= mrt.x;\n            _720 *= mrt.w;\n        }\n    }\n    return Surface(_255.xyz, _255.w, _709, clamp(fa_mesh_fs_params[5].x * _326.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _326.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_368.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _398), _714, _715, fa_mesh_fs_params[21].xyz, _717, _718, fa_mesh_fs_params[20].w, _720, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, inout Surface s)\n{\n    s.emission += (i.vertex_color.xyz * (i.uv.x * 2.0));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _620 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _620 = -_620;\n    }\n    vec3 _532 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _620, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _620, fa_world_tangent, fa_uv, fa_vertex_color, _532, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _547 = normalize(param_2.normal);\n    vec3 _562 = normalize(vec3(dot(fa_pre_r0, _547), dot(fa_pre_r1, _547), dot(fa_pre_r2, _547)));\n    float _574 = _562.z;\n    vec2 e = _562.xy / vec2((abs(_562.x) + abs(_562.y)) + abs(_574));\n    if (_574 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 800,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_228",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 50,
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
