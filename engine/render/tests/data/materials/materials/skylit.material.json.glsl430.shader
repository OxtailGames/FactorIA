{
  "format": "factoria.shader/1",
  "engine": "0.34.0",
  "template": "d5ad4ba00a2086cd5c3d6440d2be629e3ce9b0f8ede644c9a19112677c2fea28",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4227[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1466 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1473;\n    if (!_1466)\n    {\n        _1473 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1473 = _1466;\n    }\n    bool _1481;\n    if (!_1473)\n    {\n        _1481 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1481 = _1473;\n    }\n    bool _1488;\n    if (!_1481)\n    {\n        _1488 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1488 = _1481;\n    }\n    bool _1495;\n    if (!_1488)\n    {\n        _1495 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1495 = _1488;\n    }\n    if (_1495)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1505 = vec4(world_pos, 1.0);\n    float _1511 = dot(fa_mesh_fs_params[16], _1505);\n    if (!(_1511 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1533 = vec2(dot(fa_mesh_fs_params[14], _1505), dot(fa_mesh_fs_params[15], _1505)) / vec2(_1511);\n    int _1537 = int(fa_mesh_fs_params[18].x);\n    int _1541 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1541) + clamp(int(floor(((_1533.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1541 - 1)) * _1537)) + clamp(int(floor(((_1533.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1537 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1617 = fa_cluster_texel(param);\n    return ivec2(int(_1617.x), int(_1617.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5050 = fa_cluster_lookup(param);\n    fa_cl_slot = _5050.x;\n    fa_cl_local = _5050.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5262 = fa_linear_to_srgb(param);\n        c = _5262;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5270 = fa_srgb_to_linear(param_1);\n            c = _5270;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _382;\n    if (i.front_facing)\n    {\n        _382 = i.world_normal;\n    }\n    else\n    {\n        _382 = -i.world_normal;\n    }\n    vec3 _406 = normalize(i.world_tangent.xyz - (_382 * dot(_382, i.world_tangent.xyz)));\n    vec3 _433 = normalize(((_406 * m.x) + ((cross(_382, _406) * i.world_tangent.w) * m.y)) + (_382 * m.z));\n    vec3 _436;\n    if (i.front_facing)\n    {\n        _436 = _433;\n    }\n    else\n    {\n        _436 = -_433;\n    }\n    return _436;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5301 = fa_tex_fix(param_2, param_3);\n    vec4 _7185 = base_t;\n    _7185.x = _5301.x;\n    _7185.y = _5301.y;\n    _7185.z = _5301.z;\n    base_t = _7185;\n    vec4 _5315 = (_7185 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6991 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5347 = fa_tex_fix(param_6, param_7);\n        vec3 _5350 = (_5347 * 2.0) - vec3(1.0);\n        vec2 _5355 = _5350.xy * fa_mesh_fs_params[6].x;\n        vec3 _7193 = _5350;\n        _7193.x = _5355.x;\n        _7193.y = _5355.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7193;\n        _6991 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5383 = fa_tex_fix(param_12, param_13);\n    vec4 _7196 = mrt;\n    _7196.x = _5383.x;\n    _7196.y = _5383.y;\n    _7196.z = _5383.z;\n    mrt = _7196;\n    vec4 _5411 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5411.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5422 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5452 = fa_tex_fix(param_20, param_21);\n    float _6996 = fa_mesh_fs_params[20].x;\n    float _6997 = fa_mesh_fs_params[20].y;\n    float _7000 = fa_mesh_fs_params[20].z;\n    float _6999 = fa_mesh_fs_params[21].w;\n    float _7002 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6996 *= _5422.y;\n            _6997 *= _5422.z;\n            _6999 *= _5411.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7000 *= mrt.x;\n            _7002 *= mrt.w;\n        }\n    }\n    return Surface(_5315.xyz, _5315.w, _6991, clamp(fa_mesh_fs_params[5].x * _5383.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5383.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5422.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5452), _6996, _6997, fa_mesh_fs_params[21].xyz, _6999, _7000, fa_mesh_fs_params[20].w, _7002, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1697 = rect.zw - rect.xy;\n    vec2 _1701 = _1697 * atlas;\n    vec2 _1705 = ddx * _1701;\n    vec2 _1709 = ddy * _1701;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1697), clamp(0.5 * log2(max(max(dot(_1705, _1705), dot(_1709, _1709)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1742 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1749;\n    if (!_1742)\n    {\n        _1749 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1749 = _1742;\n    }\n    if (_1749)\n    {\n        return;\n    }\n    vec3 _1755 = dFdx(world_pos);\n    vec3 _1758 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1762 = fa_cluster_texel(param);\n    int _1766 = int(_1762.w);\n    if (_1766 < 1)\n    {\n        return;\n    }\n    int _1776 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1776;\n    vec4 _1780 = fa_light_texel(param_1);\n    vec2 _1783 = _1780.yz;\n    int _1787 = int(_1780.w);\n    int param_2 = _1776 + 1;\n    vec4 _1792 = fa_light_texel(param_2);\n    float _1793 = _1792.x;\n    int _1799 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1803 = int(_1762.z);\n    vec3 _2068;\n    for (int k = 0; k < _1766; k++)\n    {\n        int _1816 = _1803 + k;\n        int param_3 = _1787 + (_1816 >> 2);\n        int _1833 = (_1776 + 2) + (int(fa_light_texel(param_3)[_1816 & 3]) * 7);\n        int param_4 = _1833 + 6;\n        vec4 _1838 = fa_light_texel(param_4);\n        if (((int(_1838.w + 0.5) >> _1799) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1833;\n        vec4 _1853 = fa_light_texel(param_5);\n        int param_6 = _1833 + 1;\n        vec4 _1858 = fa_light_texel(param_6);\n        int param_7 = _1833 + 2;\n        vec4 _1863 = fa_light_texel(param_7);\n        vec3 _1866 = _1853.xyz;\n        float _1871 = dot(_1866, world_pos) + _1853.w;\n        vec3 _1873 = _1858.xyz;\n        float _1878 = dot(_1873, world_pos) + _1858.w;\n        vec3 _1880 = _1863.xyz;\n        float _1885 = dot(_1880, world_pos) + _1863.w;\n        bool _1890 = abs(_1871) > 0.5;\n        bool _1898;\n        if (!_1890)\n        {\n            _1898 = abs(_1878) > 0.5;\n        }\n        else\n        {\n            _1898 = _1890;\n        }\n        bool _1906;\n        if (!_1898)\n        {\n            _1906 = abs(_1885) > 0.5;\n        }\n        else\n        {\n            _1906 = _1898;\n        }\n        if (_1906)\n        {\n            continue;\n        }\n        float _1921 = clamp(dot(geo_normal, normalize(_1880)) * _1838.z, 0.0, 1.0);\n        if (_1921 <= 0.0)\n        {\n            continue;\n        }\n        float _1941 = (clamp((0.5 - abs(_1885)) * 10.0, 0.0, 1.0) * _1921) * _1838.x;\n        vec2 _1949 = vec2(_1871 + 0.5, 0.5 - _1878);\n        vec2 _1959 = vec2(dot(_1866, _1755), dot(_1873, _1755));\n        vec2 _1969 = vec2(dot(_1866, _1758), dot(_1873, _1758));\n        int param_8 = _1833 + 5;\n        vec4 _1974 = fa_light_texel(param_8);\n        int param_9 = _1833 + 3;\n        vec4 _1979 = fa_light_texel(param_9);\n        int param_10 = _1833 + 4;\n        vec4 _1984 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1974.xyz;\n        bool _1994 = _1979.z > _1979.x;\n        if (_1994)\n        {\n            vec4 param_11 = _1979;\n            vec2 param_12 = _1949;\n            vec2 param_13 = _1783;\n            vec2 param_14 = _1959;\n            vec2 param_15 = _1969;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1793 > 0.5) && (_1793 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2020 = fa_dc_to_linear(param_16);\n                vec4 _7079 = tx;\n                _7079.x = _2020.x;\n                _7079.y = _2020.y;\n                _7079.z = _2020.z;\n                tx = _7079;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1941 * tex_a) * _1974.w, 0.0, 1.0)));\n        if (_1984.z > _1984.x)\n        {\n            vec4 param_17 = _1984;\n            vec2 param_18 = _1949;\n            vec2 param_19 = _1783;\n            vec2 param_20 = _1959;\n            vec2 param_21 = _1969;\n            vec4 _2064 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1793 > 1.5)\n            {\n                vec3 param_22 = _2064.xyz;\n                vec3 _2074 = fa_dc_to_srgb(param_22);\n                _2068 = _2074;\n            }\n            else\n            {\n                _2068 = _2064.xyz;\n            }\n            vec3 _2083 = (_2068 * 2.0) - vec3(1.0);\n            vec2 _2088 = _2083.xy * _1838.y;\n            vec3 _2110 = (normalize(_1866) * _2088.x) + (normalize(_1873) * _2088.y);\n            vec3 _2113 = normalize(normal);\n            normal = normalize(mix(_2113, normalize((_2113 * max(_2083.z, 0.0500000007450580596923828125)) + (_2110 - (_2113 * dot(_2113, _2110)))), vec3(clamp(_1941 * (_1994 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _472 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _475;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _475 = _472 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _475 = _472 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_475)\n        {\n            discard;\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3320 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3320;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3933 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3938 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3933 > 0.0005000000237487256526947021484375)\n    {\n        if (_3938)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3933;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3933;\n        }\n    }\n    bool _3989 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3989)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4020 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4020)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3938 || _3989) || _4020)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3340 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3343 = _3340.x;\n    float _3345 = _3340.z;\n    vec2 e = vec2(_3343, _3345);\n    if (_3340.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3345)) * ((_3343 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3343)) * ((_3345 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _5564 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _5569 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _5574 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _5579 = fa_light_texel(param_3);\n    bool _5582 = _5579.z < 0.5;\n    bool _5590;\n    if (!_5582)\n    {\n        _5590 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _5590 = _5582;\n    }\n    if (_5590)\n    {\n        return vec3(0.0);\n    }\n    float _5597 = max(_5564.w, 9.9999997473787516355514526367188e-05);\n    vec3 _5600 = _5569.xyz;\n    vec3 _5604 = _5564.xyz;\n    vec3 _5608 = (fa_world_pos - _5604) / vec3(_5597);\n    vec3 _5617 = min(_5608 + vec3(0.5), (_5600 - vec3(0.5)) - _5608);\n    float _5626 = min(_5617.x, min(_5617.y, _5617.z));\n    if (!(_5626 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5641 = _5600 - vec3(1.0);\n    vec3 _5642 = clamp(_5608, vec3(0.0), _5641);\n    vec3 _5650 = min(floor(_5642), max(_5600 - vec3(2.0), vec3(0.0)));\n    vec3 _5654 = _5642 - _5650;\n    vec3 _5665 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _5597));\n    int _5670 = int(_5574.y + 0.5);\n    float _5675 = 0.3257350027561187744140625 * n.y;\n    float _5679 = 0.3257350027561187744140625 * n.z;\n    float _5683 = 0.3257350027561187744140625 * n.x;\n    float _5690 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _5697 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _5706 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _5713 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _5726 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _5733 = 8 + int(_5579.w);\n    float _5760;\n    float _5773;\n    float _5787;\n    for (int k = 0; k < _5733; k++)\n    {\n        float _5746 = float(k & 1);\n        float _5750 = float((k >> 1) & 1);\n        float _5754 = float((k >> 2) & 1);\n        if (_5746 > 0.5)\n        {\n            _5760 = _5654.x;\n        }\n        else\n        {\n            _5760 = 1.0 - _5654.x;\n        }\n        if (_5750 > 0.5)\n        {\n            _5773 = _5654.y;\n        }\n        else\n        {\n            _5773 = 1.0 - _5654.y;\n        }\n        if (_5754 > 0.5)\n        {\n            _5787 = _5654.z;\n        }\n        else\n        {\n            _5787 = 1.0 - _5654.z;\n        }\n        float _5797 = (_5760 * _5773) * _5787;\n        if (!(_5797 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5810 = min(_5650 + vec3(_5746, _5750, _5754), _5641);\n        int _5830 = int(((_5574.x + _5810.x) + (_5569.x * (_5810.y + (_5569.y * _5810.z)))) + 0.5);\n        vec2 _5845 = vec2(float(_5830 % _5670) * 10.0, 1024.0 + (float(_5830 / _5670) * 11.0));\n        vec2 param_4 = _5845 + vec2(9.5, 10.5);\n        vec4 _5853 = fa_gi_fetch(param_4);\n        bool _5856 = _5853.y < 0.5;\n        bool _5865;\n        if (!_5856)\n        {\n            _5865 = _5853.x > _5579.y;\n        }\n        else\n        {\n            _5865 = _5856;\n        }\n        if (_5865)\n        {\n            continue;\n        }\n        vec3 _5877 = _5665 - (_5604 + (_5810 * _5597));\n        float _5880 = length(_5877);\n        vec3 _5886 = _5877 / vec3(max(_5880, 9.9999997473787516355514526367188e-05));\n        float _5896 = max(9.9999997473787516355514526367188e-05, (dot(-_5886, n) + 1.0) * 0.5);\n        float w = _5797 * (_5896 * _5896);\n        vec3 param_5 = _5886;\n        vec2 param_6 = (_5845 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5915 = fa_gi_fetch(param_6);\n        float _5922 = _5880 / max(_5574.z, 9.9999997473787516355514526367188e-05);\n        float _5925 = _5915.x;\n        if (_5922 > _5925)\n        {\n            float _5938 = max(_5915.y - (_5925 * _5925), 0.0);\n            float _5943 = _5922 - _5925;\n            float _5952 = _5938 / max(_5938 + (_5943 * _5943), 9.9999999600419720025001879548654e-13);\n            w *= ((_5952 * _5952) * _5952);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5845 + vec2(0.5, 10.5);\n        vec2 param_8 = _5845 + vec2(1.5, 10.5);\n        vec2 param_9 = _5845 + vec2(2.5, 10.5);\n        vec2 param_10 = _5845 + vec2(3.5, 10.5);\n        vec2 param_11 = _5845 + vec2(4.5, 10.5);\n        vec2 param_12 = _5845 + vec2(5.5, 10.5);\n        vec2 param_13 = _5845 + vec2(6.5, 10.5);\n        vec2 param_14 = _5845 + vec2(7.5, 10.5);\n        vec2 param_15 = _5845 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _5675)) + (fa_gi_fetch(param_9).xyz * _5679)) + (fa_gi_fetch(param_10).xyz * _5683)) + (fa_gi_fetch(param_11).xyz * _5690)) + (fa_gi_fetch(param_12).xyz * _5697)) + (fa_gi_fetch(param_13).xyz * _5706)) + (fa_gi_fetch(param_14).xyz * _5713)) + (fa_gi_fetch(param_15).xyz * _5726)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_5626 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6077;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6077 = _5579.x;\n    }\n    else\n    {\n        _6077 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_5574.w * _6077);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6101 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6106 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6111 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6111) && (k < 8); k++)\n    {\n        int param = _6106 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6101;\n        vec3 _6136 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6141 = param_3 * left;\n        acc += (_6136 * _6141);\n        left -= _6141;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6170 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6170;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4152 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4160 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4163 = int(_4152);\n    int _4166 = int(_4160);\n    float _4176 = _4160 - float(_4166);\n    int _4231 = (_4163 * 9) + _4166;\n    int _4251 = ((_4163 + 1) * 9) + _4166;\n    return mix(mix(_4227[_4231], _4227[_4231 + 1], _4176), mix(_4227[_4251], _4227[_4251 + 1], _4176), _4152 - float(_4163));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6850 = false;\n    float _6851 = 1.0;\n    float _6852 = 1.0;\n    float _6853 = 1.0;\n    float _6854 = 0.0;\n    float _6855 = 0.0;\n    float _6856 = 0.0;\n    float _6857 = 0.0;\n    float _6859 = 1.0;\n    bool _6860 = false;\n    vec3 _6861 = vec3(0.0);\n    float _6862 = 1.0;\n    float _6863 = 1.0;\n    float _6864 = 1.0;\n    float _6865 = 0.0;\n    float _6866 = 0.0;\n    vec3 _6867 = vec3(1.0, 0.0, 0.0);\n    vec3 _6868 = vec3(0.0, 0.0, 1.0);\n    float _6869 = 1.0;\n    float _6870 = 1.0;\n    float _4302 = clamp(s.specular, 0.0, 1.0);\n    float _4306 = clamp(s.ior, 1.0, 3.0);\n    bool _4311 = (_4302 != 1.0) || (_4306 != 1.5);\n    bool _4320;\n    if (!_4311)\n    {\n        _4320 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4320 = _4311;\n    }\n    if (_4320)\n    {\n        float _4328 = (_4306 - 1.0) / (_4306 + 1.0);\n        f0 = mix(min(vec3(_4328 * _4328) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4302, s.albedo, vec3(metallic));\n        _6851 = mix(_4302, 1.0, metallic);\n        _6850 = true;\n    }\n    float _4355 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4355 > 0.0)\n    {\n        float _4363 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6854 = _4355;\n        _6855 = _4363;\n        float _4370 = _4363 * _4363;\n        _6856 = _4370;\n        _6857 = _4370 * _4370;\n        float _4382 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6859 = _4382;\n        _6852 = 1.0 - (_4355 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4382, 0.0, 1.0), 5.0))));\n        _6850 = true;\n    }\n    vec3 _4401 = max(s.sheen_color, vec3(0.0));\n    float _4410 = max(_4401.x, max(_4401.y, _4401.z));\n    if (_4410 > 0.0)\n    {\n        float _4418 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6860 = true;\n        _6861 = _4401;\n        _6862 = _4418;\n        _6863 = _4418 * _4418;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4418;\n        float _4435 = fa_sheen_albedo(param, param_1);\n        _6865 = _4435;\n        _6864 = 1.0 - min(_4410 * _4435, 1.0);\n        _6850 = true;\n    }\n    _6853 = _6852 * _6864;\n    float _4454 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4454 != 0.0)\n    {\n        vec3 _4469 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4469;\n        if (dot(_4469, _4469) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4481 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4481.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4481.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4481.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4485 = t;\n        vec3 _4486 = normalize(_4485);\n        t = _4486;\n        vec3 _4511 = normalize((_4486 * cos(s.anisotropy_rotation)) + ((cross(n, _4486) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6867 = _4511;\n        _6868 = cross(n, _4511);\n        float _4521 = roughness * roughness;\n        float _4527 = mix(_4521, 1.0, _4454 * _4454);\n        bool _4529 = _4454 > 0.0;\n        _6869 = _4529 ? _4527 : _4521;\n        _6870 = _4529 ? _4521 : _4527;\n        _6866 = _4454;\n        _6850 = true;\n    }\n    return FaLayers(_6850, _6851, _6852, _6853, _6854, _6855, _6856, _6857, i.world_normal, _6859, _6860, _6861, _6862, _6863, _6864, _6865, _6866, _6867, _6868, _6869, _6870);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4084 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4087 = _4084.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4087 * _4087, exp2((-9.27999973297119140625) * ndv)) * _4087) + _4084.y)) + _4084.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3392;\n    if (lv == 0)\n    {\n        _3392 = 0.0;\n    }\n    else\n    {\n        _3392 = res + 2.0;\n    }\n    float _3402;\n    if (lv == 0)\n    {\n        _3402 = 0.0;\n    }\n    else\n    {\n        _3402 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3392, _3402)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3448;\n    if (res > 64.5)\n    {\n        _3448 = 5.0;\n    }\n    else\n    {\n        _3448 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3463 = clamp(rough, 0.0, 1.0) * (_3448 - 1.0);\n    int _3470 = int(min(floor(_3463), _3448 - 2.0));\n    float _3475 = _3463 - float(_3470);\n    vec3 param = d;\n    vec2 _3479 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3470;\n    vec2 param_4 = _3479;\n    vec3 _3489 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3475 < 0.00200000009499490261077880859375)\n    {\n        return _3489;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3470 + 1;\n    vec2 param_8 = _3479;\n    return mix(_3489, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3475));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3562 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3569 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3576 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3582 = dot(bx.xyz, d);\n    float _3586 = dot(by.xyz, d);\n    float _3590 = dot(bz.xyz, d);\n    float _3596;\n    if (_3582 > 9.9999999747524270787835121154785e-07)\n    {\n        _3596 = (1.0 - _3562) / _3582;\n    }\n    else\n    {\n        float _3610;\n        if (_3582 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3610 = ((-1.0) - _3562) / _3582;\n        }\n        else\n        {\n            _3610 = 1000000015047466219876688855040.0;\n        }\n        _3596 = _3610;\n    }\n    float tx = _3596;\n    float _3627;\n    if (_3586 > 9.9999999747524270787835121154785e-07)\n    {\n        _3627 = (1.0 - _3569) / _3586;\n    }\n    else\n    {\n        float _3640;\n        if (_3586 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3640 = ((-1.0) - _3569) / _3586;\n        }\n        else\n        {\n            _3640 = 1000000015047466219876688855040.0;\n        }\n        _3627 = _3640;\n    }\n    float ty = _3627;\n    float _3656;\n    if (_3590 > 9.9999999747524270787835121154785e-07)\n    {\n        _3656 = (1.0 - _3576) / _3590;\n    }\n    else\n    {\n        float _3669;\n        if (_3590 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3669 = ((-1.0) - _3576) / _3590;\n        }\n        else\n        {\n            _3669 = 1000000015047466219876688855040.0;\n        }\n        _3656 = _3669;\n    }\n    float _3681 = tx;\n    float _3684 = (_3681 > 0.0) ? _3681 : 1000000015047466219876688855040.0;\n    tx = _3684;\n    float _3685 = ty;\n    float _3688 = (_3685 > 0.0) ? _3685 : 1000000015047466219876688855040.0;\n    ty = _3688;\n    float _3698 = min(_3684, min(_3688, (_3656 > 0.0) ? _3656 : 1000000015047466219876688855040.0));\n    if (_3698 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3714 = (fa_world_pos + (d * _3698)) - posw.xyz;\n    vec3 _3719;\n    if (dot(_3714, _3714) > 1.0000000133514319600180897396058e-10)\n    {\n        _3719 = normalize(_3714);\n    }\n    else\n    {\n        _3719 = d;\n    }\n    return _3719;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3765 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3765 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3793 = rough * rough;\n            float _3824 = 0.60000002384185791015625 * _3793;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3793)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3824, 0.0500000007450580596923828125 + _3824, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3793 * 0.60000002384185791015625));\n        }\n        outc = base * _3765;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3883 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3883 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3915 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3915 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4562;\n        if (L.aniso >= 0.0)\n        {\n            _4562 = L.b;\n        }\n        else\n        {\n            _4562 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4562, v), _4562), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4598 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4598.x) + (vec3(L.f90) * _4598.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4656 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4656.x) + _4656.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4126 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4126.x) + vec3(_4126.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4685 = clamp(s.metallic, 0.0, 1.0);\n    float _4689 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4696 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4685));\n    vec3 f0 = _4696;\n    vec3 _4700 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4700;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4685;\n    float param_5 = _4689;\n    vec3 param_6 = _4696;\n    FaLayers _4717 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4717.on)\n    {\n        FaLayers param_7 = _4717;\n        vec3 param_8 = _4700;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4689;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4700;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4689;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5020;\n    if (fa_lm.z > 0.5)\n    {\n        _5020 = 0.0;\n    }\n    else\n    {\n        _5020 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5031 = _5020 < 1.0;\n    bool _5037;\n    if (_5031)\n    {\n        int param = li;\n        _5037 = fa_light_baked(param);\n    }\n    else\n    {\n        _5037 = _5031;\n    }\n    return _5037 ? _5020 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _716 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _729 = (c - (ru * hx)) - p;\n        vec3 _735 = ru * (2.0 * hx);\n        float _741 = max(dot(_735, _735), 9.9999999392252902907785028219223e-09);\n        float _745 = dot(_729, _735);\n        float t = clamp((-_745) / _741, 0.0, 1.0);\n        if (_716)\n        {\n            float _760 = dot(r, _735);\n            float _766 = _741 - (_760 * _760);\n            if (abs(_766) > (9.9999997473787516355514526367188e-06 * _741))\n            {\n                t = clamp(((dot(r, _729) * _760) - _745) / _766, 0.0, 1.0);\n            }\n        }\n        return (p + _729) + (_735 * t);\n    }\n    vec3 q = p;\n    float _798 = dot(r, axis);\n    bool _806;\n    if (_716)\n    {\n        _806 = abs(_798) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _806 = _716;\n    }\n    if (_806)\n    {\n        float _816 = dot(c - p, axis) / _798;\n        if (_816 > 0.0)\n        {\n            q = p + (r * _816);\n        }\n    }\n    vec3 _829 = q - c;\n    vec2 xy = vec2(dot(_829, ru), dot(_829, uu));\n    if (shape > 0.5)\n    {\n        float _844 = length(xy);\n        if (_844 > hx)\n        {\n            xy *= (hx / _844);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _636 = dot(d, right);\n    float _640 = dot(d, up);\n    float _651;\n    if (((_636 * _636) + (_640 * _640)) > 1.0000000133514319600180897396058e-10)\n    {\n        _651 = atan(_640, _636) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _651 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_651 - floor(_651)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _492 = abs(d);\n    float _494 = _492.x;\n    float _496 = _492.y;\n    bool _497 = _494 >= _496;\n    bool _505;\n    if (_497)\n    {\n        _505 = _494 >= _492.z;\n    }\n    else\n    {\n        _505 = _497;\n    }\n    int _506;\n    if (_505)\n    {\n        _506 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _520;\n        if (_496 >= _492.z)\n        {\n            _520 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _520 = (d.z > 0.0) ? 4 : 5;\n        }\n        _506 = _520;\n    }\n    return _506;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _882 = fa_light_base(param);\n    bool _886 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _882;\n    vec4 _890 = fa_light_texel(param_1);\n    int param_2 = _882 + 1;\n    vec4 _895 = fa_light_texel(param_2);\n    float _898 = _895.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _910 = _886 && (_898 > 2.5);\n    fa_light_is_area = _910;\n    bool _912 = _898 < 0.5;\n    vec3 l;\n    if (_912)\n    {\n        l = normalize(_890.xyz);\n        if (_886)\n        {\n            int param_3 = _882 + 6;\n            vec4 _926 = fa_light_texel(param_3);\n            if (_926.z > 0.5)\n            {\n                int param_4 = _882 + 4;\n                vec4 _936 = fa_light_texel(param_4);\n                int param_5 = _882 + 5;\n                vec4 _941 = fa_light_texel(param_5);\n                vec2 param_6 = _926.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _936.xyz) * _936.w, (-dot(world_pos, _941.xyz)) * _941.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _971 = _890.xyz;\n        vec3 _973 = _971 - world_pos;\n        vec3 to_light = _973;\n        float _976 = length(_973);\n        float reach = _976;\n        bool front = true;\n        if (_910)\n        {\n            int param_8 = _882 + 7;\n            reach = max(_976 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _882 + 4;\n            vec4 _1000 = fa_light_texel(param_9);\n            int param_10 = _882 + 5;\n            vec4 _1005 = fa_light_texel(param_10);\n            int param_11 = _882 + 6;\n            vec4 _1010 = fa_light_texel(param_11);\n            float _1011 = _1010.w;\n            int param_12 = _882 + 2;\n            vec3 _1018 = normalize(fa_light_texel(param_12).xyz);\n            bool _1020 = _1011 > 1.5;\n            bool _1028;\n            if (!_1020)\n            {\n                _1028 = dot(_1018, to_light) < 0.0;\n            }\n            else\n            {\n                _1028 = _1020;\n            }\n            front = _1028;\n            vec3 r = vec3(0.0);\n            vec3 _1037 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1041 = dot(n, n) > 0.5;\n            bool _1049;\n            if (_1041)\n            {\n                _1049 = dot(_1037, _1037) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1049 = _1041;\n            }\n            if (_1049)\n            {\n                r = reflect(-normalize(_1037), normalize(n));\n            }\n            vec3 param_13 = _971;\n            vec3 param_14 = _1018;\n            vec3 param_15 = _1000.xyz;\n            vec3 param_16 = _1005.xyz;\n            float param_17 = _1000.w;\n            float param_18 = _1005.w;\n            float param_19 = _1011;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1085 = length(to_light);\n        dist = _1085;\n        l = to_light / vec3(max(_1085, 9.9999997473787516355514526367188e-05));\n        float _1099 = reach / max(_890.w, 0.001000000047497451305389404296875);\n        float _1105 = clamp(1.0 - (_1099 * _1099), 0.0, 1.0);\n        float _1107;\n        if (front)\n        {\n            _1107 = _1105 * _1105;\n        }\n        else\n        {\n            _1107 = 0.0;\n        }\n        atten = _1107;\n        bool _1118 = _898 < 2.5;\n        if ((_898 > 1.5) && _1118)\n        {\n            int param_22 = _882 + 2;\n            vec4 _1126 = fa_light_texel(param_22);\n            float _1136 = _1126.w;\n            int param_23 = _882 + 3;\n            vec4 _1141 = fa_light_texel(param_23);\n            float _1142 = _1141.x;\n            float cos_inner = _1142;\n            if (_1142 > 1.5)\n            {\n                cos_inner = mix(_1136, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1136, cos_inner, dot(-l, normalize(_1126.xyz)));\n        }\n        if (_886 && (_898 < 1.5))\n        {\n            int param_24 = _882 + 6;\n            vec4 _1166 = fa_light_texel(param_24);\n            if (_1166.z > 0.5)\n            {\n                vec3 _1174 = -to_light;\n                int param_25 = _882 + 4;\n                int param_26 = _882 + 5;\n                vec3 _1188 = fa_light_texel(param_25).xyz;\n                vec3 _1192 = fa_light_texel(param_26).xyz;\n                vec3 _1201 = vec3(dot(_1174, _1188), dot(_1174, _1192), dot(_1174, cross(_1188, _1192)));\n                vec3 param_27 = _1201;\n                int _1205 = fa_cube_face(param_27);\n                int param_28 = _1205;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1232 = vec2(dot(_1201, cross(param_29, param_30)), dot(_1201, param_30)) / vec2(max(dot(_1201, param_29), 9.9999997473787516355514526367188e-05));\n                int _1236 = _1205 / 3;\n                vec2 param_31 = _1166.xy + (vec2(float(_1205 - (_1236 * 3)), float(_1236)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1232.x), 0.5 - (0.5 * _1232.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _882 + 7;\n            vec4 _1266 = fa_light_texel(param_33);\n            if (_1266.z > 0.5)\n            {\n                int param_34 = _882 + 2;\n                int param_35 = _882 + 4;\n                int param_36 = _882 + 5;\n                vec2 param_37 = _1266.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_886 && _1118)\n            {\n                int param_42 = _882 + 6;\n                vec4 _1313 = fa_light_texel(param_42);\n                int param_43 = _882 + 7;\n                vec4 _1318 = fa_light_texel(param_43);\n                bool _1321 = _1313.z > 0.5;\n                bool _1328;\n                if (!_1321)\n                {\n                    _1328 = _1318.z > 0.5;\n                }\n                else\n                {\n                    _1328 = _1321;\n                }\n                if (_1328)\n                {\n                    int param_44 = _882 + 2;\n                    vec4 _1335 = fa_light_texel(param_44);\n                    vec3 _1339 = normalize(_1335.xyz);\n                    int param_45 = _882 + 4;\n                    vec4 _1344 = fa_light_texel(param_45);\n                    int param_46 = _882 + 5;\n                    vec4 _1349 = fa_light_texel(param_46);\n                    if (_1321)\n                    {\n                        vec3 _1357 = -to_light;\n                        float _1364 = _1335.w;\n                        float _1380 = 0.5 / max(dot(_1357, _1339) * (sqrt(max(1.0 - (_1364 * _1364), 0.0)) / max(_1364, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1313.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1357, _1344.xyz) * _1380), 0.5 - (dot(_1357, _1349.xyz) * _1380));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1318.z > 0.5)\n                    {\n                        vec2 param_49 = _1318.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1339;\n                        vec3 param_52 = _1344.xyz;\n                        vec3 param_53 = _1349.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6838 = _895.xyz * atten;\n    if (_886)\n    {\n        _6838 *= fa_light_tint;\n    }\n    int _1448;\n    if (_912)\n    {\n        _1448 = 0;\n    }\n    else\n    {\n        _1448 = ((_898 > 1.5) && (_898 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6838, atten, 1.0, dist, _1448);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2231 = fa_shadow_depth(param, param_1);\n    float _2235;\n    if (conv.x < 0.5)\n    {\n        _2235 = _2231;\n    }\n    else\n    {\n        _2235 = (conv.y * conv.z) / (conv.z - (_2231 * (conv.z - conv.y)));\n    }\n    return _2235;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2281 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2287 = vec2(cos(_2281), sin(_2281));\n    vec2 dir = _2287;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2296;\n        if (k < 0.0)\n        {\n            _2296 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2296 = k;\n        }\n        float _2315 = clamp((_2296 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2334 = sqrt((float(i) + 0.5) * 0.0625) * _2315;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2334));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2348 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2348 < (zr - (_2334 * plane)))\n            {\n                sum += _2348;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2376 = sum / cnt;\n        float _2386;\n        if (k < 0.0)\n        {\n            _2386 = (-k) / max(_2376, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2386 = k;\n        }\n        radius = clamp(((max(zr - _2376, 0.0) * unit) * _2386) / texel_m, 1.5, 16.0);\n        dir = _2287;\n    }\n    float lit = 0.0;\n    int _2412 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2412; i_1++)\n    {\n        float _2431 = sqrt((float(i_1) + 0.5) / float(_2412)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2431));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2431 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2412);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2636 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2643;\n    if (!_2636)\n    {\n        _2643 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2643 = _2636;\n    }\n    if (_2643)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2656 = fa_light_texel(param);\n    float _2657 = _2656.x;\n    if (_2657 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2666 = int(_2657 + 0.5);\n    int param_1 = _2666;\n    vec4 _2670 = fa_light_texel(param_1);\n    int param_2 = _2666 + 1;\n    vec4 _2675 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2678 = _2670.y;\n    if (_2678 > 0.0)\n    {\n        float _2695 = 1.0 - smoothstep(0.75 * _2678, _2678, length(world - fa_shadows[27].xyz));\n        fade = _2695;\n        if (_2695 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2670.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2719 = (_2666 + 2) + (face * 6);\n    int param_4 = _2719;\n    int param_5 = _2719 + 1;\n    int param_6 = _2719 + 3;\n    vec4 _2733 = fa_light_texel(param_6);\n    int param_7 = _2719 + 4;\n    vec4 _2738 = fa_light_texel(param_7);\n    int param_8 = _2719 + 5;\n    vec4 _2743 = fa_light_texel(param_8);\n    float _2755 = _2743.x * max(dot(_2733, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2760 = clamp(dot(n, l), 0.0, 1.0);\n    float _2783 = clamp(dot(n, _2733.xyz), -1.0, 1.0);\n    float _2802 = min(sqrt(1.0 - (_2783 * _2783)) / max(abs(dot(n, world - lpos)) / max(dot(_2733, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2805 = _2675.y;\n    float _2807;\n    if (_2805 > 0.0)\n    {\n        _2807 = _2805;\n    }\n    else\n    {\n        _2807 = 1.5 * _2755;\n    }\n    vec4 _2827 = vec4(world + (n * (_2807 * sqrt(1.0 - (_2760 * _2760)))), 1.0);\n    float _2831 = dot(_2733, _2827);\n    float _2834 = _2743.y;\n    if (_2831 < _2834)\n    {\n        return 1.0;\n    }\n    vec2 _2849 = vec2(dot(fa_light_texel(param_4), _2827), dot(fa_light_texel(param_5), _2827)) / vec2(_2831);\n    float _2851 = _2849.x;\n    bool _2854 = _2851 < _2738.x;\n    bool _2863;\n    if (!_2854)\n    {\n        _2863 = _2851 > _2738.z;\n    }\n    else\n    {\n        _2863 = _2854;\n    }\n    bool _2872;\n    if (!_2863)\n    {\n        _2872 = _2849.y < _2738.y;\n    }\n    else\n    {\n        _2872 = _2863;\n    }\n    bool _2881;\n    if (!_2872)\n    {\n        _2881 = _2849.y > _2738.w;\n    }\n    else\n    {\n        _2881 = _2872;\n    }\n    if (_2881)\n    {\n        return 1.0;\n    }\n    float _2887 = _2675.x;\n    float _2889;\n    if (_2887 > 0.0)\n    {\n        _2889 = _2887;\n    }\n    else\n    {\n        _2889 = 1.5 * _2755;\n    }\n    vec2 param_9 = _2849;\n    vec4 param_10 = _2738;\n    float param_11 = _2831 - (_2889 * (1.0 + (0.5 * _2802)));\n    float param_12 = _2755;\n    float param_13 = 1.0;\n    float param_14 = _2743.z * 0.25;\n    float param_15 = (_2755 * min(_2802, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2834, _2743.z);\n    int param_17 = int(_2670.z + 0.5);\n    float param_18 = _2670.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2174;\n    if (i == 0)\n    {\n        _2174 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2190;\n        if (i == 1)\n        {\n            _2190 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2198;\n            if (i == 2)\n            {\n                _2198 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2198 = fa_shadows[24].w;\n            }\n            _2190 = _2198;\n        }\n        _2174 = _2190;\n    }\n    return _2174;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2477 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2482 = clamp(dot(n, l), 0.0, 1.0);\n    float _2488 = sqrt(1.0 - (_2482 * _2482));\n    float _2496 = min(_2488 / max(_2482, 0.20000000298023223876953125), 4.0);\n    float _2501;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2501 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2501 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2526 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2501 * _2488)), 1.0);\n    float _2533 = _2526.x;\n    bool _2536 = _2533 < fa_shadows[ci * 1 + 16].x;\n    bool _2545;\n    if (!_2536)\n    {\n        _2545 = _2533 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2545 = _2536;\n    }\n    bool _2554;\n    if (!_2545)\n    {\n        _2554 = _2526.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2554 = _2545;\n    }\n    bool _2563;\n    if (!_2554)\n    {\n        _2563 = _2526.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2563 = _2554;\n    }\n    bool _2570;\n    if (!_2563)\n    {\n        _2570 = _2526.z > 1.0;\n    }\n    else\n    {\n        _2570 = _2563;\n    }\n    if (_2570)\n    {\n        return -1.0;\n    }\n    float _2578;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2578 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2578 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2526.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2526.z - ((_2578 * (1.0 + (0.5 * _2496))) / _2477);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2477;\n    float param_5 = _2477 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2496, 3.0)) * 0.5) / _2477;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2956 = int(fa_shadows[25].x + 0.5);\n    if (_2956 < 1)\n    {\n        return 1.0;\n    }\n    float _2971 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2956 - 1;\n    if (_2971 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2983 = _2956 > 1;\n    bool _2990;\n    if (_2983)\n    {\n        _2990 = _2971 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2990 = _2983;\n    }\n    if (_2990)\n    {\n        ci = 1;\n    }\n    bool _2994 = _2956 > 2;\n    bool _3001;\n    if (_2994)\n    {\n        _3001 = _2971 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3001 = _2994;\n    }\n    if (_3001)\n    {\n        ci = 2;\n    }\n    bool _3005 = _2956 > 3;\n    bool _3012;\n    if (_3005)\n    {\n        _3012 = _2971 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3012 = _3005;\n    }\n    if (_3012)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3023 = min(_2956, 4);\n    float _3064;\n    for (int c = ci; c < _3023; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3043 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3043;\n            break;\n        }\n        if (_3043 < 0.0)\n        {\n            continue;\n        }\n        s = _3043;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3064 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3064 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3083 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3064, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2971 - (fa_shadow_split_at(param_7) - _3083)) / _3083, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3115;\n        if ((ci + 1) < _2956)\n        {\n            _3115 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3115 = 1.0;\n        }\n        s = mix(s, _3115, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4756 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4763;\n    if (!_4756)\n    {\n        _4763 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4763 = _4756;\n    }\n    if (_4763)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4776 = fa_light_texel(param);\n    float _4777 = _4776.y;\n    float len = _4777;\n    if (_4777 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4789 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4799 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4789);\n    if (_4799 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4805 = len;\n    float _4808 = min(_4805, 0.89999997615814208984375 * dist);\n    len = _4808;\n    float _4813 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4789);\n    float _4818 = _4813 + (0.5 * _4808);\n    vec3 _4824 = world + (gn * _4813);\n    float _4826 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4890;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4841 = (float(k) + _4826) * 0.083333335816860198974609375;\n        vec3 _4849 = _4824 + (l * (_4841 * len));\n        vec4 _4855 = vec4(_4849, 1.0);\n        float _4861 = dot(fa_mesh_fs_params[28], _4855);\n        if (_4861 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4881 = vec2(dot(fa_mesh_fs_params[26], _4855), dot(fa_mesh_fs_params[27], _4855)) / vec2(_4861);\n        float _4885 = _4881.x * 0.5;\n        float _4886 = _4885 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4890 = (_4881.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4890 = 0.5 - (_4881.y * 0.5);\n        }\n        bool _4906 = _4886 < 0.0;\n        bool _4913;\n        if (!_4906)\n        {\n            _4913 = _4886 >= 1.0;\n        }\n        else\n        {\n            _4913 = _4906;\n        }\n        bool _4920;\n        if (!_4913)\n        {\n            _4920 = _4890 < 0.0;\n        }\n        else\n        {\n            _4920 = _4913;\n        }\n        bool _4927;\n        if (!_4920)\n        {\n            _4927 = _4890 >= 1.0;\n        }\n        else\n        {\n            _4927 = _4920;\n        }\n        if (_4927)\n        {\n            break;\n        }\n        vec4 _4954 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4886, _4890) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4954.w < 0.5)\n        {\n            continue;\n        }\n        float _4973 = (dot(fa_mesh_fs_params[29].xyz, _4849) + fa_mesh_fs_params[29].w) - _4954.x;\n        if ((_4973 > _4813) && (_4973 < _4818))\n        {\n            occ = max(occ, (1.0 - (_4841 * _4841)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4886, 0.5 - _4885), min(_4890, 1.0 - _4890))));\n        }\n    }\n    return 1.0 - (occ * _4799);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5076 = fa_baked_keep(param);\n    if (_5076 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5102 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6971 = _5102.color;\n    float _6972 = _5102.attenuation;\n    float _6973 = _5102.shadow;\n    bool _5105 = _5102.type == 0;\n    if (_5105 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5102.direction;\n        float _5116 = fa_shadow_factor(param_5, param_6);\n        _6973 = _5116;\n        _6971 *= _5116;\n    }\n    else\n    {\n        bool _5127 = _5102.type != 0;\n        bool _5133;\n        if (_5127)\n        {\n            _5133 = _6972 > 0.0;\n        }\n        else\n        {\n            _5133 = _5127;\n        }\n        if (_5133)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5102.direction;\n            float _5152 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6973 = _5152;\n            _6971 *= _5152;\n        }\n    }\n    bool _5162 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5168;\n    if (_5162)\n    {\n        _5168 = _6972 > 0.0;\n    }\n    else\n    {\n        _5168 = _5162;\n    }\n    if (_5168)\n    {\n        float _5175;\n        if (_5105)\n        {\n            _5175 = 1000000000.0;\n        }\n        else\n        {\n            _5175 = _5102._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5102.direction;\n        float param_18 = _5175;\n        float _5193 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6973 *= _5193;\n        _6971 *= _5193;\n    }\n    float _5206 = _6972;\n    float _5207 = _5206 * _5076;\n    _6972 = _5207;\n    vec3 _5211 = _6971;\n    vec3 _5212 = _5211 * _5076;\n    _6971 = _5212;\n    return LightSample(_5102.direction, _5212, _5207, _6973, _5102._distance, _5102.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3143 = int(fa_shadows[25].x + 0.5);\n    float _3153 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3158 = _3143 > 0;\n    bool _3167;\n    if (_3158)\n    {\n        int param = _3143 - 1;\n        _3167 = _3153 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3167 = _3158;\n    }\n    if (_3167)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3173 = _3143 > 1;\n        bool _3180;\n        if (_3173)\n        {\n            _3180 = _3153 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3180 = _3173;\n        }\n        if (_3180)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3186 = _3143 > 2;\n        bool _3193;\n        if (_3186)\n        {\n            _3193 = _3153 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3193 = _3186;\n        }\n        if (_3193)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3199 = _3143 > 3;\n        bool _3206;\n        if (_3199)\n        {\n            _3206 = _3153 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3206 = _3199;\n        }\n        if (_3206)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6656 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6656 = -_6656;\n    }\n    vec3 _6278 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6656, fa_world_tangent, fa_uv, fa_vertex_color, _6278, gl_FrontFacing);\n    Surface _6286 = fa_standard_surface(param_1);\n    vec3 _6695 = _6286.albedo;\n    float _6696 = _6286.alpha;\n    vec3 _6697 = _6286.normal;\n    float _6698 = _6286.metallic;\n    float _6699 = _6286.roughness;\n    float _6700 = _6286.occlusion;\n    vec3 _6701 = _6286.emission;\n    float _6702 = _6286.clearcoat;\n    float _6703 = _6286.clearcoat_roughness;\n    vec3 _6704 = _6286.sheen_color;\n    float _6705 = _6286.sheen_roughness;\n    float _6706 = _6286.anisotropy;\n    float _6707 = _6286.anisotropy_rotation;\n    float _6708 = _6286.specular;\n    float _6709 = _6286.ior;\n    vec3 _6710 = _6286.specular_color;\n    float _6711 = _6286.transmission;\n    float _6712 = _6286.thickness;\n    vec3 _6713 = _6286.attenuation_color;\n    float _6714 = _6286.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6656, fa_world_tangent, fa_uv, fa_vertex_color, _6278, gl_FrontFacing);\n    Surface param_3 = _6286;\n    surface(param_2, param_3);\n    _6695 = param_3.albedo;\n    _6696 = param_3.alpha;\n    _6697 = param_3.normal;\n    _6698 = param_3.metallic;\n    _6699 = param_3.roughness;\n    _6700 = param_3.occlusion;\n    _6701 = param_3.emission;\n    _6702 = param_3.clearcoat;\n    _6703 = param_3.clearcoat_roughness;\n    _6704 = param_3.sheen_color;\n    _6705 = param_3.sheen_roughness;\n    _6706 = param_3.anisotropy;\n    _6707 = param_3.anisotropy_rotation;\n    _6708 = param_3.specular;\n    _6709 = param_3.ior;\n    _6710 = param_3.specular_color;\n    _6711 = param_3.transmission;\n    _6712 = param_3.thickness;\n    _6713 = param_3.attenuation_color;\n    _6714 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6656;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6695 = param_6;\n    _6697 = param_7;\n    fa_lod_dither();\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6695;\n    }\n    else\n    {\n        vec3 _6326 = _6697;\n        vec3 _6327 = normalize(_6326);\n        _6697 = _6327;\n        vec3 param_8 = _6327;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _6656, fa_world_tangent, fa_uv, fa_vertex_color, _6278, gl_FrontFacing);\n        Surface param_10 = Surface(_6695, _6696, _6697, _6698, _6699, _6700, _6701, _6702, _6703, _6704, _6705, _6706, _6707, _6708, _6709, _6710, _6711, _6712, _6713, _6714);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6346 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6346; ln++)\n        {\n            int param_12 = ln;\n            int _6359 = fa_cl_light(param_12);\n            int param_13 = _6359;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6359;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _6656;\n            LightSample _6375 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _6656, fa_world_tangent, fa_uv, fa_vertex_color, _6278, gl_FrontFacing);\n            Surface param_18 = Surface(_6695, _6696, _6697, _6698, _6699, _6700, _6701, _6702, _6703, _6704, _6705, _6706, _6707, _6708, _6709, _6710, _6711, _6712, _6713, _6714);\n            LightSample param_19 = _6375;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6390 = result;\n    vec3 _6391 = _6390 + _6701;\n    result = _6391;\n    vec3 param_20 = _6391;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6400 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6407;\n    if (!_6400)\n    {\n        _6407 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6407 = _6400;\n    }\n    if (_6407)\n    {\n        vec3 _6416 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6422 = dot(_6416, fa_mesh_fs_params[9].xyz);\n        bool _6426 = fa_mesh_fs_params[9].w > 0.5;\n        float _6427;\n        if (_6426)\n        {\n            _6427 = _6422;\n        }\n        else\n        {\n            _6427 = length(_6416);\n        }\n        float _6439 = _6427 - fa_mesh_fs_params[8].x;\n        if (_6439 > 0.0)\n        {\n            float _6448 = fa_mesh_fs_params[7].w * _6439;\n            float tau = _6448 * _6448;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6464;\n                if (_6426)\n                {\n                    _6464 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6422);\n                }\n                else\n                {\n                    _6464 = fa_mesh_fs_params[0].y;\n                }\n                float _6485 = mix(_6464, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6427, 0.0, 1.0));\n                float _6489 = fa_world_pos.y - _6485;\n                float _6494 = _6485 - fa_mesh_fs_params[8].z;\n                float _6499 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6502 = _6494 <= 0.0;\n                bool _6503 = !_6502;\n                bool _6509;\n                if (_6503)\n                {\n                    _6509 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6509 = _6502;\n                }\n                float _6510;\n                if (_6509)\n                {\n                    _6510 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6510 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6494, 80.0));\n                }\n                bool _6537;\n                if (_6503)\n                {\n                    _6537 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6537 = _6502;\n                }\n                float _6538;\n                if (_6537)\n                {\n                    _6538 = fa_mesh_fs_params[8].y * _6494;\n                }\n                else\n                {\n                    _6538 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6494, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6563 = _6499 <= 0.0;\n                bool _6570;\n                if (!_6563)\n                {\n                    _6570 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6570 = _6563;\n                }\n                float _6571;\n                if (_6570)\n                {\n                    _6571 = fa_mesh_fs_params[8].y * _6499;\n                }\n                else\n                {\n                    _6571 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6499, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6598;\n                if (abs(_6489) < 0.001000000047497451305389404296875)\n                {\n                    _6598 = _6510;\n                }\n                else\n                {\n                    _6598 = (_6571 - _6538) / _6489;\n                }\n                tau += (_6439 * max(_6598, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6696);\n}\n\n",
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
            "inst_name": "_450",
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
            "inst_name": "_2184",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _4227[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[53];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_probe_atlas_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1466 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1473;\n    if (!_1466)\n    {\n        _1473 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1473 = _1466;\n    }\n    bool _1481;\n    if (!_1473)\n    {\n        _1481 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1481 = _1473;\n    }\n    bool _1488;\n    if (!_1481)\n    {\n        _1488 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1488 = _1481;\n    }\n    bool _1495;\n    if (!_1488)\n    {\n        _1495 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1495 = _1488;\n    }\n    if (_1495)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1505 = vec4(world_pos, 1.0);\n    float _1511 = dot(fa_mesh_fs_params[16], _1505);\n    if (!(_1511 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1533 = vec2(dot(fa_mesh_fs_params[14], _1505), dot(fa_mesh_fs_params[15], _1505)) / vec2(_1511);\n    int _1537 = int(fa_mesh_fs_params[18].x);\n    int _1541 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1541) + clamp(int(floor(((_1533.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1541 - 1)) * _1537)) + clamp(int(floor(((_1533.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1537 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1617 = fa_cluster_texel(param);\n    return ivec2(int(_1617.x), int(_1617.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _5050 = fa_cluster_lookup(param);\n    fa_cl_slot = _5050.x;\n    fa_cl_local = _5050.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _5262 = fa_linear_to_srgb(param);\n        c = _5262;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _5270 = fa_srgb_to_linear(param_1);\n            c = _5270;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _382;\n    if (i.front_facing)\n    {\n        _382 = i.world_normal;\n    }\n    else\n    {\n        _382 = -i.world_normal;\n    }\n    vec3 _406 = normalize(i.world_tangent.xyz - (_382 * dot(_382, i.world_tangent.xyz)));\n    vec3 _433 = normalize(((_406 * m.x) + ((cross(_382, _406) * i.world_tangent.w) * m.y)) + (_382 * m.z));\n    vec3 _436;\n    if (i.front_facing)\n    {\n        _436 = _433;\n    }\n    else\n    {\n        _436 = -_433;\n    }\n    return _436;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _5301 = fa_tex_fix(param_2, param_3);\n    vec4 _7185 = base_t;\n    _7185.x = _5301.x;\n    _7185.y = _5301.y;\n    _7185.z = _5301.z;\n    base_t = _7185;\n    vec4 _5315 = (_7185 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _6991 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _5347 = fa_tex_fix(param_6, param_7);\n        vec3 _5350 = (_5347 * 2.0) - vec3(1.0);\n        vec2 _5355 = _5350.xy * fa_mesh_fs_params[6].x;\n        vec3 _7193 = _5350;\n        _7193.x = _5355.x;\n        _7193.y = _5355.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _7193;\n        _6991 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _5383 = fa_tex_fix(param_12, param_13);\n    vec4 _7196 = mrt;\n    _7196.x = _5383.x;\n    _7196.y = _5383.y;\n    _7196.z = _5383.z;\n    mrt = _7196;\n    vec4 _5411 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _5411.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _5422 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _5452 = fa_tex_fix(param_20, param_21);\n    float _6996 = fa_mesh_fs_params[20].x;\n    float _6997 = fa_mesh_fs_params[20].y;\n    float _7000 = fa_mesh_fs_params[20].z;\n    float _6999 = fa_mesh_fs_params[21].w;\n    float _7002 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _6996 *= _5422.y;\n            _6997 *= _5422.z;\n            _6999 *= _5411.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _7000 *= mrt.x;\n            _7002 *= mrt.w;\n        }\n    }\n    return Surface(_5315.xyz, _5315.w, _6991, clamp(fa_mesh_fs_params[5].x * _5383.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _5383.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_5422.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _5452), _6996, _6997, fa_mesh_fs_params[21].xyz, _6999, _7000, fa_mesh_fs_params[20].w, _7002, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1697 = rect.zw - rect.xy;\n    vec2 _1701 = _1697 * atlas;\n    vec2 _1705 = ddx * _1701;\n    vec2 _1709 = ddy * _1701;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1697), clamp(0.5 * log2(max(max(dot(_1705, _1705), dot(_1709, _1709)), 9.9999999392252902907785028219223e-09)), 0.0, 3.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1742 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1749;\n    if (!_1742)\n    {\n        _1749 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1749 = _1742;\n    }\n    if (_1749)\n    {\n        return;\n    }\n    vec3 _1755 = dFdx(world_pos);\n    vec3 _1758 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1762 = fa_cluster_texel(param);\n    int _1766 = int(_1762.w);\n    if (_1766 < 1)\n    {\n        return;\n    }\n    int _1776 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1776;\n    vec4 _1780 = fa_light_texel(param_1);\n    vec2 _1783 = _1780.yz;\n    int _1787 = int(_1780.w);\n    int param_2 = _1776 + 1;\n    vec4 _1792 = fa_light_texel(param_2);\n    float _1793 = _1792.x;\n    int _1799 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1803 = int(_1762.z);\n    vec3 _2068;\n    for (int k = 0; k < _1766; k++)\n    {\n        int _1816 = _1803 + k;\n        int param_3 = _1787 + (_1816 >> 2);\n        int _1833 = (_1776 + 2) + (int(fa_light_texel(param_3)[_1816 & 3]) * 7);\n        int param_4 = _1833 + 6;\n        vec4 _1838 = fa_light_texel(param_4);\n        if (((int(_1838.w + 0.5) >> _1799) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1833;\n        vec4 _1853 = fa_light_texel(param_5);\n        int param_6 = _1833 + 1;\n        vec4 _1858 = fa_light_texel(param_6);\n        int param_7 = _1833 + 2;\n        vec4 _1863 = fa_light_texel(param_7);\n        vec3 _1866 = _1853.xyz;\n        float _1871 = dot(_1866, world_pos) + _1853.w;\n        vec3 _1873 = _1858.xyz;\n        float _1878 = dot(_1873, world_pos) + _1858.w;\n        vec3 _1880 = _1863.xyz;\n        float _1885 = dot(_1880, world_pos) + _1863.w;\n        bool _1890 = abs(_1871) > 0.5;\n        bool _1898;\n        if (!_1890)\n        {\n            _1898 = abs(_1878) > 0.5;\n        }\n        else\n        {\n            _1898 = _1890;\n        }\n        bool _1906;\n        if (!_1898)\n        {\n            _1906 = abs(_1885) > 0.5;\n        }\n        else\n        {\n            _1906 = _1898;\n        }\n        if (_1906)\n        {\n            continue;\n        }\n        float _1921 = clamp(dot(geo_normal, normalize(_1880)) * _1838.z, 0.0, 1.0);\n        if (_1921 <= 0.0)\n        {\n            continue;\n        }\n        float _1941 = (clamp((0.5 - abs(_1885)) * 10.0, 0.0, 1.0) * _1921) * _1838.x;\n        vec2 _1949 = vec2(_1871 + 0.5, 0.5 - _1878);\n        vec2 _1959 = vec2(dot(_1866, _1755), dot(_1873, _1755));\n        vec2 _1969 = vec2(dot(_1866, _1758), dot(_1873, _1758));\n        int param_8 = _1833 + 5;\n        vec4 _1974 = fa_light_texel(param_8);\n        int param_9 = _1833 + 3;\n        vec4 _1979 = fa_light_texel(param_9);\n        int param_10 = _1833 + 4;\n        vec4 _1984 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1974.xyz;\n        bool _1994 = _1979.z > _1979.x;\n        if (_1994)\n        {\n            vec4 param_11 = _1979;\n            vec2 param_12 = _1949;\n            vec2 param_13 = _1783;\n            vec2 param_14 = _1959;\n            vec2 param_15 = _1969;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1793 > 0.5) && (_1793 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _2020 = fa_dc_to_linear(param_16);\n                vec4 _7079 = tx;\n                _7079.x = _2020.x;\n                _7079.y = _2020.y;\n                _7079.z = _2020.z;\n                tx = _7079;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1941 * tex_a) * _1974.w, 0.0, 1.0)));\n        if (_1984.z > _1984.x)\n        {\n            vec4 param_17 = _1984;\n            vec2 param_18 = _1949;\n            vec2 param_19 = _1783;\n            vec2 param_20 = _1959;\n            vec2 param_21 = _1969;\n            vec4 _2064 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1793 > 1.5)\n            {\n                vec3 param_22 = _2064.xyz;\n                vec3 _2074 = fa_dc_to_srgb(param_22);\n                _2068 = _2074;\n            }\n            else\n            {\n                _2068 = _2064.xyz;\n            }\n            vec3 _2083 = (_2068 * 2.0) - vec3(1.0);\n            vec2 _2088 = _2083.xy * _1838.y;\n            vec3 _2110 = (normalize(_1866) * _2088.x) + (normalize(_1873) * _2088.y);\n            vec3 _2113 = normalize(normal);\n            normal = normalize(mix(_2113, normalize((_2113 * max(_2083.z, 0.0500000007450580596923828125)) + (_2110 - (_2113 * dot(_2113, _2110)))), vec3(clamp(_1941 * (_1994 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _472 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _475;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _475 = _472 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _475 = _472 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_475)\n        {\n            discard;\n        }\n    }\n}\n\nvec2 fa_atlas_size()\n{\n    return vec2(textureSize(fa_probe_atlas_fa_env_smp, 0));\n}\n\nvec3 fa_probe_sh_coef(vec2 origin, float res, int k)\n{\n    vec3 v = textureLod(fa_probe_atlas_fa_env_smp, (origin + vec2(float(k) + 0.5, res + 2.5)) / fa_atlas_size(), 0.0).xyz;\n    if (fa_mesh_fs_params[41].y > 0.5)\n    {\n        v = ((v * 255.0) - vec3(128.0)) * 0.03149606287479400634765625;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3320 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3320;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    float _3933 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 amb = vec3(0.0);\n    bool _3938 = fa_mesh_fs_params[11].w > 0.5;\n    vec3 c[9];\n    for (int k = 0; k < 9; k++)\n    {\n        c[k] = vec3(0.0);\n    }\n    if (_3933 > 0.0005000000237487256526947021484375)\n    {\n        if (_3938)\n        {\n            for (int k_1 = 0; k_1 < 9; k_1++)\n            {\n                vec2 param = fa_mesh_fs_params[41].zw;\n                float param_1 = 128.0;\n                int param_2 = k_1;\n                c[k_1] = fa_probe_sh_coef(param, param_1, param_2) * _3933;\n            }\n        }\n        else\n        {\n            amb = fa_mesh_fs_params[1].xyz * _3933;\n        }\n    }\n    bool _3989 = fa_mesh_fs_params[42].w > 0.0;\n    if (_3989)\n    {\n        for (int k_2 = 0; k_2 < 9; k_2++)\n        {\n            vec2 param_3 = fa_mesh_fs_params[42].xy;\n            float param_4 = fa_mesh_fs_params[42].z;\n            int param_5 = k_2;\n            c[k_2] += (fa_probe_sh_coef(param_3, param_4, param_5) * fa_mesh_fs_params[42].w);\n        }\n    }\n    bool _4020 = fa_mesh_fs_params[47].w > 0.0;\n    if (_4020)\n    {\n        for (int k_3 = 0; k_3 < 9; k_3++)\n        {\n            vec2 param_6 = fa_mesh_fs_params[47].xy;\n            float param_7 = fa_mesh_fs_params[47].z;\n            int param_8 = k_3;\n            c[k_3] += (fa_probe_sh_coef(param_6, param_7, param_8) * fa_mesh_fs_params[47].w);\n        }\n    }\n    if ((_3938 || _3989) || _4020)\n    {\n        vec3 param_9[9] = c;\n        vec3 param_10 = n;\n        amb += fa_sh_eval(param_9, param_10);\n    }\n    return amb;\n}\n\nvec4 fa_gi_fetch(vec2 texel)\n{\n    return textureLod(fa_probe_atlas_fa_env_smp, texel / fa_atlas_size(), 0.0);\n}\n\nvec2 fa_oct_encode(vec3 d)\n{\n    vec3 _3340 = d / vec3(max((abs(d.x) + abs(d.y)) + abs(d.z), 9.9999999600419720025001879548654e-13));\n    float _3343 = _3340.x;\n    float _3345 = _3340.z;\n    vec2 e = vec2(_3343, _3345);\n    if (_3340.y < 0.0)\n    {\n        e = vec2((1.0 - abs(_3345)) * ((_3343 < 0.0) ? (-1.0) : 1.0), (1.0 - abs(_3343)) * ((_3345 < 0.0) ? (-1.0) : 1.0));\n    }\n    return e;\n}\n\nvec3 fa_gi_grid(int rec, vec3 n, vec3 v, out float cover)\n{\n    cover = 0.0;\n    int param = rec;\n    vec4 _5564 = fa_light_texel(param);\n    int param_1 = rec + 1;\n    vec4 _5569 = fa_light_texel(param_1);\n    int param_2 = rec + 2;\n    vec4 _5574 = fa_light_texel(param_2);\n    int param_3 = rec + 3;\n    vec4 _5579 = fa_light_texel(param_3);\n    bool _5582 = _5579.z < 0.5;\n    bool _5590;\n    if (!_5582)\n    {\n        _5590 = fa_atlas_size().y < 1155.0;\n    }\n    else\n    {\n        _5590 = _5582;\n    }\n    if (_5590)\n    {\n        return vec3(0.0);\n    }\n    float _5597 = max(_5564.w, 9.9999997473787516355514526367188e-05);\n    vec3 _5600 = _5569.xyz;\n    vec3 _5604 = _5564.xyz;\n    vec3 _5608 = (fa_world_pos - _5604) / vec3(_5597);\n    vec3 _5617 = min(_5608 + vec3(0.5), (_5600 - vec3(0.5)) - _5608);\n    float _5626 = min(_5617.x, min(_5617.y, _5617.z));\n    if (!(_5626 > 0.0))\n    {\n        return vec3(0.0);\n    }\n    vec3 _5641 = _5600 - vec3(1.0);\n    vec3 _5642 = clamp(_5608, vec3(0.0), _5641);\n    vec3 _5650 = min(floor(_5642), max(_5600 - vec3(2.0), vec3(0.0)));\n    vec3 _5654 = _5642 - _5650;\n    vec3 _5665 = fa_world_pos + (((n * 0.800000011920928955078125) + (v * 0.20000000298023223876953125)) * (0.20000000298023223876953125 * _5597));\n    int _5670 = int(_5574.y + 0.5);\n    float _5675 = 0.3257350027561187744140625 * n.y;\n    float _5679 = 0.3257350027561187744140625 * n.z;\n    float _5683 = 0.3257350027561187744140625 * n.x;\n    float _5690 = (0.2731371223926544189453125 * n.x) * n.y;\n    float _5697 = (0.2731371223926544189453125 * n.y) * n.z;\n    float _5706 = 0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0);\n    float _5713 = (0.2731371223926544189453125 * n.x) * n.z;\n    float _5726 = 0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y));\n    vec3 acc = vec3(0.0);\n    float wsum = 0.0;\n    int _5733 = 8 + int(_5579.w);\n    float _5760;\n    float _5773;\n    float _5787;\n    for (int k = 0; k < _5733; k++)\n    {\n        float _5746 = float(k & 1);\n        float _5750 = float((k >> 1) & 1);\n        float _5754 = float((k >> 2) & 1);\n        if (_5746 > 0.5)\n        {\n            _5760 = _5654.x;\n        }\n        else\n        {\n            _5760 = 1.0 - _5654.x;\n        }\n        if (_5750 > 0.5)\n        {\n            _5773 = _5654.y;\n        }\n        else\n        {\n            _5773 = 1.0 - _5654.y;\n        }\n        if (_5754 > 0.5)\n        {\n            _5787 = _5654.z;\n        }\n        else\n        {\n            _5787 = 1.0 - _5654.z;\n        }\n        float _5797 = (_5760 * _5773) * _5787;\n        if (!(_5797 > 0.0))\n        {\n            continue;\n        }\n        vec3 _5810 = min(_5650 + vec3(_5746, _5750, _5754), _5641);\n        int _5830 = int(((_5574.x + _5810.x) + (_5569.x * (_5810.y + (_5569.y * _5810.z)))) + 0.5);\n        vec2 _5845 = vec2(float(_5830 % _5670) * 10.0, 1024.0 + (float(_5830 / _5670) * 11.0));\n        vec2 param_4 = _5845 + vec2(9.5, 10.5);\n        vec4 _5853 = fa_gi_fetch(param_4);\n        bool _5856 = _5853.y < 0.5;\n        bool _5865;\n        if (!_5856)\n        {\n            _5865 = _5853.x > _5579.y;\n        }\n        else\n        {\n            _5865 = _5856;\n        }\n        if (_5865)\n        {\n            continue;\n        }\n        vec3 _5877 = _5665 - (_5604 + (_5810 * _5597));\n        float _5880 = length(_5877);\n        vec3 _5886 = _5877 / vec3(max(_5880, 9.9999997473787516355514526367188e-05));\n        float _5896 = max(9.9999997473787516355514526367188e-05, (dot(-_5886, n) + 1.0) * 0.5);\n        float w = _5797 * (_5896 * _5896);\n        vec3 param_5 = _5886;\n        vec2 param_6 = (_5845 + vec2(1.0)) + (((fa_oct_encode(param_5) * 0.5) + vec2(0.5)) * 8.0);\n        vec4 _5915 = fa_gi_fetch(param_6);\n        float _5922 = _5880 / max(_5574.z, 9.9999997473787516355514526367188e-05);\n        float _5925 = _5915.x;\n        if (_5922 > _5925)\n        {\n            float _5938 = max(_5915.y - (_5925 * _5925), 0.0);\n            float _5943 = _5922 - _5925;\n            float _5952 = _5938 / max(_5938 + (_5943 * _5943), 9.9999999600419720025001879548654e-13);\n            w *= ((_5952 * _5952) * _5952);\n        }\n        if (!(w > 0.0))\n        {\n            continue;\n        }\n        vec2 param_7 = _5845 + vec2(0.5, 10.5);\n        vec2 param_8 = _5845 + vec2(1.5, 10.5);\n        vec2 param_9 = _5845 + vec2(2.5, 10.5);\n        vec2 param_10 = _5845 + vec2(3.5, 10.5);\n        vec2 param_11 = _5845 + vec2(4.5, 10.5);\n        vec2 param_12 = _5845 + vec2(5.5, 10.5);\n        vec2 param_13 = _5845 + vec2(6.5, 10.5);\n        vec2 param_14 = _5845 + vec2(7.5, 10.5);\n        vec2 param_15 = _5845 + vec2(8.5, 10.5);\n        acc += ((((((((((fa_gi_fetch(param_7).xyz * 0.2820948064327239990234375) + (fa_gi_fetch(param_8).xyz * _5675)) + (fa_gi_fetch(param_9).xyz * _5679)) + (fa_gi_fetch(param_10).xyz * _5683)) + (fa_gi_fetch(param_11).xyz * _5690)) + (fa_gi_fetch(param_12).xyz * _5697)) + (fa_gi_fetch(param_13).xyz * _5706)) + (fa_gi_fetch(param_14).xyz * _5713)) + (fa_gi_fetch(param_15).xyz * _5726)) * w);\n        wsum += w;\n    }\n    if (!(wsum > 9.9999997473787516355514526367188e-06))\n    {\n        return vec3(0.0);\n    }\n    cover = smoothstep(0.0, 1.0, clamp(_5626 * 2.0, 0.0, 1.0)) * smoothstep(0.0, 0.0199999995529651641845703125, wsum);\n    float _6077;\n    if (fa_mesh_fs_params[52].z > 0.5)\n    {\n        _6077 = _5579.x;\n    }\n    else\n    {\n        _6077 = 1.0;\n    }\n    return max(acc / vec3(wsum), vec3(0.0)) * (_5574.w * _6077);\n}\n\nvec3 fa_gi_light(vec3 n, inout float left)\n{\n    left = 1.0;\n    vec3 acc = vec3(0.0);\n    vec3 _6101 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    int _6106 = int(fa_mesh_fs_params[52].x + 0.5);\n    int _6111 = int(fa_mesh_fs_params[52].y + 0.5);\n    float param_3;\n    for (int k = 0; (k < _6111) && (k < 8); k++)\n    {\n        int param = _6106 + (4 * k);\n        vec3 param_1 = n;\n        vec3 param_2 = _6101;\n        vec3 _6136 = fa_gi_grid(param, param_1, param_2, param_3);\n        float _6141 = param_3 * left;\n        acc += (_6136 * _6141);\n        left -= _6141;\n        if (left < 0.001000000047497451305389404296875)\n        {\n            left = 0.0;\n            break;\n        }\n    }\n    return acc;\n}\n\nvec3 fa_realtime_or_ambient(vec3 n)\n{\n    vec3 gi = vec3(0.0);\n    float left = 1.0;\n    if (fa_mesh_fs_params[52].y > 0.5)\n    {\n        vec3 param = n;\n        float param_1;\n        vec3 _6170 = fa_gi_light(param, param_1);\n        left = param_1;\n        gi = _6170;\n    }\n    if (left <= 0.0)\n    {\n        return gi;\n    }\n    vec3 param_2 = n;\n    return gi + (fa_ambient_light(param_2) * left);\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[32].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 32].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[32].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_realtime_or_ambient(param_3);\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _4152 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _4160 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _4163 = int(_4152);\n    int _4166 = int(_4160);\n    float _4176 = _4160 - float(_4166);\n    int _4231 = (_4163 * 9) + _4166;\n    int _4251 = ((_4163 + 1) * 9) + _4166;\n    return mix(mix(_4227[_4231], _4227[_4231 + 1], _4176), mix(_4227[_4251], _4227[_4251 + 1], _4176), _4152 - float(_4163));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _6850 = false;\n    float _6851 = 1.0;\n    float _6852 = 1.0;\n    float _6853 = 1.0;\n    float _6854 = 0.0;\n    float _6855 = 0.0;\n    float _6856 = 0.0;\n    float _6857 = 0.0;\n    float _6859 = 1.0;\n    bool _6860 = false;\n    vec3 _6861 = vec3(0.0);\n    float _6862 = 1.0;\n    float _6863 = 1.0;\n    float _6864 = 1.0;\n    float _6865 = 0.0;\n    float _6866 = 0.0;\n    vec3 _6867 = vec3(1.0, 0.0, 0.0);\n    vec3 _6868 = vec3(0.0, 0.0, 1.0);\n    float _6869 = 1.0;\n    float _6870 = 1.0;\n    float _4302 = clamp(s.specular, 0.0, 1.0);\n    float _4306 = clamp(s.ior, 1.0, 3.0);\n    bool _4311 = (_4302 != 1.0) || (_4306 != 1.5);\n    bool _4320;\n    if (!_4311)\n    {\n        _4320 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _4320 = _4311;\n    }\n    if (_4320)\n    {\n        float _4328 = (_4306 - 1.0) / (_4306 + 1.0);\n        f0 = mix(min(vec3(_4328 * _4328) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _4302, s.albedo, vec3(metallic));\n        _6851 = mix(_4302, 1.0, metallic);\n        _6850 = true;\n    }\n    float _4355 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_4355 > 0.0)\n    {\n        float _4363 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _6854 = _4355;\n        _6855 = _4363;\n        float _4370 = _4363 * _4363;\n        _6856 = _4370;\n        _6857 = _4370 * _4370;\n        float _4382 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _6859 = _4382;\n        _6852 = 1.0 - (_4355 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _4382, 0.0, 1.0), 5.0))));\n        _6850 = true;\n    }\n    vec3 _4401 = max(s.sheen_color, vec3(0.0));\n    float _4410 = max(_4401.x, max(_4401.y, _4401.z));\n    if (_4410 > 0.0)\n    {\n        float _4418 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _6860 = true;\n        _6861 = _4401;\n        _6862 = _4418;\n        _6863 = _4418 * _4418;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _4418;\n        float _4435 = fa_sheen_albedo(param, param_1);\n        _6865 = _4435;\n        _6864 = 1.0 - min(_4410 * _4435, 1.0);\n        _6850 = true;\n    }\n    _6853 = _6852 * _6864;\n    float _4454 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_4454 != 0.0)\n    {\n        vec3 _4469 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _4469;\n        if (dot(_4469, _4469) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _4481 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_4481.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _4481.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _4481.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _4485 = t;\n        vec3 _4486 = normalize(_4485);\n        t = _4486;\n        vec3 _4511 = normalize((_4486 * cos(s.anisotropy_rotation)) + ((cross(n, _4486) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _6867 = _4511;\n        _6868 = cross(n, _4511);\n        float _4521 = roughness * roughness;\n        float _4527 = mix(_4521, 1.0, _4454 * _4454);\n        bool _4529 = _4454 > 0.0;\n        _6869 = _4529 ? _4527 : _4521;\n        _6870 = _4529 ? _4521 : _4527;\n        _6866 = _4454;\n        _6850 = true;\n    }\n    return FaLayers(_6850, _6851, _6852, _6853, _6854, _6855, _6856, _6857, i.world_normal, _6859, _6860, _6861, _6862, _6863, _6864, _6865, _6866, _6867, _6868, _6869, _6870);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _4084 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _4087 = _4084.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_4087 * _4087, exp2((-9.27999973297119140625) * ndv)) * _4087) + _4084.y)) + _4084.zw;\n}\n\nvec3 fa_probe_level(vec2 origin, float res, int lv, vec2 e)\n{\n    float _3392;\n    if (lv == 0)\n    {\n        _3392 = 0.0;\n    }\n    else\n    {\n        _3392 = res + 2.0;\n    }\n    float _3402;\n    if (lv == 0)\n    {\n        _3402 = 0.0;\n    }\n    else\n    {\n        _3402 = (res - (res / float(1 << max((lv - 1), 0)))) + (2.0 * float(lv - 1));\n    }\n    return textureLod(fa_probe_atlas_fa_env_smp, (((origin + vec2(_3392, _3402)) + vec2(1.0)) + (((e * 0.5) + vec2(0.5)) * (res / float(1 << lv)))) / fa_atlas_size(), 0.0).xyz;\n}\n\nvec3 fa_probe_radiance(vec2 origin, float res, vec3 d, float rough)\n{\n    float _3448;\n    if (res > 64.5)\n    {\n        _3448 = 5.0;\n    }\n    else\n    {\n        _3448 = (res > 32.5) ? 4.0 : 3.0;\n    }\n    float _3463 = clamp(rough, 0.0, 1.0) * (_3448 - 1.0);\n    int _3470 = int(min(floor(_3463), _3448 - 2.0));\n    float _3475 = _3463 - float(_3470);\n    vec3 param = d;\n    vec2 _3479 = fa_oct_encode(param);\n    vec2 param_1 = origin;\n    float param_2 = res;\n    int param_3 = _3470;\n    vec2 param_4 = _3479;\n    vec3 _3489 = fa_probe_level(param_1, param_2, param_3, param_4);\n    if (_3475 < 0.00200000009499490261077880859375)\n    {\n        return _3489;\n    }\n    vec2 param_5 = origin;\n    float param_6 = res;\n    int param_7 = _3470 + 1;\n    vec2 param_8 = _3479;\n    return mix(_3489, fa_probe_level(param_5, param_6, param_7, param_8), vec3(_3475));\n}\n\nvec3 fa_probe_box_dir(vec3 d, vec4 posw, vec4 bx, vec4 by, vec4 bz)\n{\n    if (posw.w < 0.5)\n    {\n        return d;\n    }\n    float _3562 = dot(bx.xyz, fa_world_pos) + bx.w;\n    float _3569 = dot(by.xyz, fa_world_pos) + by.w;\n    float _3576 = dot(bz.xyz, fa_world_pos) + bz.w;\n    float _3582 = dot(bx.xyz, d);\n    float _3586 = dot(by.xyz, d);\n    float _3590 = dot(bz.xyz, d);\n    float _3596;\n    if (_3582 > 9.9999999747524270787835121154785e-07)\n    {\n        _3596 = (1.0 - _3562) / _3582;\n    }\n    else\n    {\n        float _3610;\n        if (_3582 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3610 = ((-1.0) - _3562) / _3582;\n        }\n        else\n        {\n            _3610 = 1000000015047466219876688855040.0;\n        }\n        _3596 = _3610;\n    }\n    float tx = _3596;\n    float _3627;\n    if (_3586 > 9.9999999747524270787835121154785e-07)\n    {\n        _3627 = (1.0 - _3569) / _3586;\n    }\n    else\n    {\n        float _3640;\n        if (_3586 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3640 = ((-1.0) - _3569) / _3586;\n        }\n        else\n        {\n            _3640 = 1000000015047466219876688855040.0;\n        }\n        _3627 = _3640;\n    }\n    float ty = _3627;\n    float _3656;\n    if (_3590 > 9.9999999747524270787835121154785e-07)\n    {\n        _3656 = (1.0 - _3576) / _3590;\n    }\n    else\n    {\n        float _3669;\n        if (_3590 < (-9.9999999747524270787835121154785e-07))\n        {\n            _3669 = ((-1.0) - _3576) / _3590;\n        }\n        else\n        {\n            _3669 = 1000000015047466219876688855040.0;\n        }\n        _3656 = _3669;\n    }\n    float _3681 = tx;\n    float _3684 = (_3681 > 0.0) ? _3681 : 1000000015047466219876688855040.0;\n    tx = _3684;\n    float _3685 = ty;\n    float _3688 = (_3685 > 0.0) ? _3685 : 1000000015047466219876688855040.0;\n    ty = _3688;\n    float _3698 = min(_3684, min(_3688, (_3656 > 0.0) ? _3656 : 1000000015047466219876688855040.0));\n    if (_3698 > 100000001504746621987668885504.0)\n    {\n        return d;\n    }\n    vec3 _3714 = (fa_world_pos + (d * _3698)) - posw.xyz;\n    vec3 _3719;\n    if (dot(_3714, _3714) > 1.0000000133514319600180897396058e-10)\n    {\n        _3719 = normalize(_3714);\n    }\n    else\n    {\n        _3719 = d;\n    }\n    return _3719;\n}\n\nvec3 fa_probe_environment(vec4 tile, vec4 posw, vec4 bx, vec4 by, vec4 bz, inout vec3 d, float rough)\n{\n    vec3 param = d;\n    vec4 param_1 = posw;\n    vec4 param_2 = bx;\n    vec4 param_3 = by;\n    vec4 param_4 = bz;\n    d = fa_probe_box_dir(param, param_1, param_2, param_3, param_4);\n    vec2 param_5 = tile.xy;\n    float param_6 = tile.z;\n    vec3 param_7 = d;\n    float param_8 = rough;\n    return fa_probe_radiance(param_5, param_6, param_7, param_8);\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    float _3765 = (1.0 - fa_mesh_fs_params[42].w) - fa_mesh_fs_params[47].w;\n    vec3 outc = vec3(0.0);\n    if (_3765 > 0.0005000000237487256526947021484375)\n    {\n        vec3 base;\n        if (fa_mesh_fs_params[11].w > 0.5)\n        {\n            vec2 param = fa_mesh_fs_params[41].zw;\n            float param_1 = 128.0;\n            vec3 param_2 = d;\n            float param_3 = rough;\n            base = fa_probe_radiance(param, param_1, param_2, param_3);\n        }\n        else\n        {\n            float _3793 = rough * rough;\n            float _3824 = 0.60000002384185791015625 * _3793;\n            base = mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3793)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3824, 0.0500000007450580596923828125 + _3824, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3793 * 0.60000002384185791015625));\n        }\n        outc = base * _3765;\n    }\n    if (fa_mesh_fs_params[42].w > 0.0)\n    {\n        vec4 param_4 = fa_mesh_fs_params[42];\n        vec4 param_5 = fa_mesh_fs_params[43];\n        vec4 param_6 = fa_mesh_fs_params[44];\n        vec4 param_7 = fa_mesh_fs_params[45];\n        vec4 param_8 = fa_mesh_fs_params[46];\n        vec3 param_9 = d;\n        float param_10 = rough;\n        vec3 _3883 = fa_probe_environment(param_4, param_5, param_6, param_7, param_8, param_9, param_10);\n        outc += (_3883 * fa_mesh_fs_params[42].w);\n    }\n    if (fa_mesh_fs_params[47].w > 0.0)\n    {\n        vec4 param_11 = fa_mesh_fs_params[47];\n        vec4 param_12 = fa_mesh_fs_params[48];\n        vec4 param_13 = fa_mesh_fs_params[49];\n        vec4 param_14 = fa_mesh_fs_params[50];\n        vec4 param_15 = fa_mesh_fs_params[51];\n        vec3 param_16 = d;\n        float param_17 = rough;\n        vec3 _3915 = fa_probe_environment(param_11, param_12, param_13, param_14, param_15, param_16, param_17);\n        outc += (_3915 * fa_mesh_fs_params[47].w);\n    }\n    return outc;\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness, float occlusion)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _4562;\n        if (L.aniso >= 0.0)\n        {\n            _4562 = L.b;\n        }\n        else\n        {\n            _4562 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_4562, v), _4562), vec3(abs(L.aniso) * smoothstep(0.0, 0.25, roughness))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4598 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _4598.x) + (vec3(L.f90) * _4598.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    result *= occlusion;\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _4656 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _4656.x) + _4656.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _4126 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _4126.x) + vec3(_4126.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _4685 = clamp(s.metallic, 0.0, 1.0);\n    float _4689 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _4696 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_4685));\n    vec3 f0 = _4696;\n    vec3 _4700 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _4700;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _4685;\n    float param_5 = _4689;\n    vec3 param_6 = _4696;\n    FaLayers _4717 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_4717.on)\n    {\n        FaLayers param_7 = _4717;\n        vec3 param_8 = _4700;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _4689;\n        float param_12 = s.occlusion;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11, param_12);\n    }\n    vec3 param_13 = _4700;\n    vec3 param_14 = i.view_dir;\n    vec3 param_15 = f0;\n    float param_16 = _4689;\n    return fa_sky_reflection(param_13, param_14, param_15, param_16) * s.occlusion;\n}\n\nvec3 ambient(SurfaceInput i, Surface s, vec3 ambientColor)\n{\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    return fa_sky_light(param, param_1);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _5020;\n    if (fa_lm.z > 0.5)\n    {\n        _5020 = 0.0;\n    }\n    else\n    {\n        _5020 = 1.0 - clamp(fa_mesh_fs_params[32].w, 0.0, 1.0);\n    }\n    bool _5031 = _5020 < 1.0;\n    bool _5037;\n    if (_5031)\n    {\n        int param = li;\n        _5037 = fa_light_baked(param);\n    }\n    else\n    {\n        _5037 = _5031;\n    }\n    return _5037 ? _5020 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _716 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _729 = (c - (ru * hx)) - p;\n        vec3 _735 = ru * (2.0 * hx);\n        float _741 = max(dot(_735, _735), 9.9999999392252902907785028219223e-09);\n        float _745 = dot(_729, _735);\n        float t = clamp((-_745) / _741, 0.0, 1.0);\n        if (_716)\n        {\n            float _760 = dot(r, _735);\n            float _766 = _741 - (_760 * _760);\n            if (abs(_766) > (9.9999997473787516355514526367188e-06 * _741))\n            {\n                t = clamp(((dot(r, _729) * _760) - _745) / _766, 0.0, 1.0);\n            }\n        }\n        return (p + _729) + (_735 * t);\n    }\n    vec3 q = p;\n    float _798 = dot(r, axis);\n    bool _806;\n    if (_716)\n    {\n        _806 = abs(_798) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _806 = _716;\n    }\n    if (_806)\n    {\n        float _816 = dot(c - p, axis) / _798;\n        if (_816 > 0.0)\n        {\n            q = p + (r * _816);\n        }\n    }\n    vec3 _829 = q - c;\n    vec2 xy = vec2(dot(_829, ru), dot(_829, uu));\n    if (shape > 0.5)\n    {\n        float _844 = length(xy);\n        if (_844 > hx)\n        {\n            xy *= (hx / _844);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _636 = dot(d, right);\n    float _640 = dot(d, up);\n    float _651;\n    if (((_636 * _636) + (_640 * _640)) > 1.0000000133514319600180897396058e-10)\n    {\n        _651 = atan(_640, _636) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _651 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_651 - floor(_651)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _492 = abs(d);\n    float _494 = _492.x;\n    float _496 = _492.y;\n    bool _497 = _494 >= _496;\n    bool _505;\n    if (_497)\n    {\n        _505 = _494 >= _492.z;\n    }\n    else\n    {\n        _505 = _497;\n    }\n    int _506;\n    if (_505)\n    {\n        _506 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _520;\n        if (_496 >= _492.z)\n        {\n            _520 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _520 = (d.z > 0.0) ? 4 : 5;\n        }\n        _506 = _520;\n    }\n    return _506;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _882 = fa_light_base(param);\n    bool _886 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _882;\n    vec4 _890 = fa_light_texel(param_1);\n    int param_2 = _882 + 1;\n    vec4 _895 = fa_light_texel(param_2);\n    float _898 = _895.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _910 = _886 && (_898 > 2.5);\n    fa_light_is_area = _910;\n    bool _912 = _898 < 0.5;\n    vec3 l;\n    if (_912)\n    {\n        l = normalize(_890.xyz);\n        if (_886)\n        {\n            int param_3 = _882 + 6;\n            vec4 _926 = fa_light_texel(param_3);\n            if (_926.z > 0.5)\n            {\n                int param_4 = _882 + 4;\n                vec4 _936 = fa_light_texel(param_4);\n                int param_5 = _882 + 5;\n                vec4 _941 = fa_light_texel(param_5);\n                vec2 param_6 = _926.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _936.xyz) * _936.w, (-dot(world_pos, _941.xyz)) * _941.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _971 = _890.xyz;\n        vec3 _973 = _971 - world_pos;\n        vec3 to_light = _973;\n        float _976 = length(_973);\n        float reach = _976;\n        bool front = true;\n        if (_910)\n        {\n            int param_8 = _882 + 7;\n            reach = max(_976 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _882 + 4;\n            vec4 _1000 = fa_light_texel(param_9);\n            int param_10 = _882 + 5;\n            vec4 _1005 = fa_light_texel(param_10);\n            int param_11 = _882 + 6;\n            vec4 _1010 = fa_light_texel(param_11);\n            float _1011 = _1010.w;\n            int param_12 = _882 + 2;\n            vec3 _1018 = normalize(fa_light_texel(param_12).xyz);\n            bool _1020 = _1011 > 1.5;\n            bool _1028;\n            if (!_1020)\n            {\n                _1028 = dot(_1018, to_light) < 0.0;\n            }\n            else\n            {\n                _1028 = _1020;\n            }\n            front = _1028;\n            vec3 r = vec3(0.0);\n            vec3 _1037 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _1041 = dot(n, n) > 0.5;\n            bool _1049;\n            if (_1041)\n            {\n                _1049 = dot(_1037, _1037) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _1049 = _1041;\n            }\n            if (_1049)\n            {\n                r = reflect(-normalize(_1037), normalize(n));\n            }\n            vec3 param_13 = _971;\n            vec3 param_14 = _1018;\n            vec3 param_15 = _1000.xyz;\n            vec3 param_16 = _1005.xyz;\n            float param_17 = _1000.w;\n            float param_18 = _1005.w;\n            float param_19 = _1011;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _1085 = length(to_light);\n        dist = _1085;\n        l = to_light / vec3(max(_1085, 9.9999997473787516355514526367188e-05));\n        float _1099 = reach / max(_890.w, 0.001000000047497451305389404296875);\n        float _1105 = clamp(1.0 - (_1099 * _1099), 0.0, 1.0);\n        float _1107;\n        if (front)\n        {\n            _1107 = _1105 * _1105;\n        }\n        else\n        {\n            _1107 = 0.0;\n        }\n        atten = _1107;\n        bool _1118 = _898 < 2.5;\n        if ((_898 > 1.5) && _1118)\n        {\n            int param_22 = _882 + 2;\n            vec4 _1126 = fa_light_texel(param_22);\n            float _1136 = _1126.w;\n            int param_23 = _882 + 3;\n            vec4 _1141 = fa_light_texel(param_23);\n            float _1142 = _1141.x;\n            float cos_inner = _1142;\n            if (_1142 > 1.5)\n            {\n                cos_inner = mix(_1136, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1136, cos_inner, dot(-l, normalize(_1126.xyz)));\n        }\n        if (_886 && (_898 < 1.5))\n        {\n            int param_24 = _882 + 6;\n            vec4 _1166 = fa_light_texel(param_24);\n            if (_1166.z > 0.5)\n            {\n                vec3 _1174 = -to_light;\n                int param_25 = _882 + 4;\n                int param_26 = _882 + 5;\n                vec3 _1188 = fa_light_texel(param_25).xyz;\n                vec3 _1192 = fa_light_texel(param_26).xyz;\n                vec3 _1201 = vec3(dot(_1174, _1188), dot(_1174, _1192), dot(_1174, cross(_1188, _1192)));\n                vec3 param_27 = _1201;\n                int _1205 = fa_cube_face(param_27);\n                int param_28 = _1205;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1232 = vec2(dot(_1201, cross(param_29, param_30)), dot(_1201, param_30)) / vec2(max(dot(_1201, param_29), 9.9999997473787516355514526367188e-05));\n                int _1236 = _1205 / 3;\n                vec2 param_31 = _1166.xy + (vec2(float(_1205 - (_1236 * 3)), float(_1236)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1232.x), 0.5 - (0.5 * _1232.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _882 + 7;\n            vec4 _1266 = fa_light_texel(param_33);\n            if (_1266.z > 0.5)\n            {\n                int param_34 = _882 + 2;\n                int param_35 = _882 + 4;\n                int param_36 = _882 + 5;\n                vec2 param_37 = _1266.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_886 && _1118)\n            {\n                int param_42 = _882 + 6;\n                vec4 _1313 = fa_light_texel(param_42);\n                int param_43 = _882 + 7;\n                vec4 _1318 = fa_light_texel(param_43);\n                bool _1321 = _1313.z > 0.5;\n                bool _1328;\n                if (!_1321)\n                {\n                    _1328 = _1318.z > 0.5;\n                }\n                else\n                {\n                    _1328 = _1321;\n                }\n                if (_1328)\n                {\n                    int param_44 = _882 + 2;\n                    vec4 _1335 = fa_light_texel(param_44);\n                    vec3 _1339 = normalize(_1335.xyz);\n                    int param_45 = _882 + 4;\n                    vec4 _1344 = fa_light_texel(param_45);\n                    int param_46 = _882 + 5;\n                    vec4 _1349 = fa_light_texel(param_46);\n                    if (_1321)\n                    {\n                        vec3 _1357 = -to_light;\n                        float _1364 = _1335.w;\n                        float _1380 = 0.5 / max(dot(_1357, _1339) * (sqrt(max(1.0 - (_1364 * _1364), 0.0)) / max(_1364, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1313.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1357, _1344.xyz) * _1380), 0.5 - (dot(_1357, _1349.xyz) * _1380));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1318.z > 0.5)\n                    {\n                        vec2 param_49 = _1318.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1339;\n                        vec3 param_52 = _1344.xyz;\n                        vec3 param_53 = _1349.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _6838 = _895.xyz * atten;\n    if (_886)\n    {\n        _6838 *= fa_light_tint;\n    }\n    int _1448;\n    if (_912)\n    {\n        _1448 = 0;\n    }\n    else\n    {\n        _1448 = ((_898 > 1.5) && (_898 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _6838, atten, 1.0, dist, _1448);\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2231 = fa_shadow_depth(param, param_1);\n    float _2235;\n    if (conv.x < 0.5)\n    {\n        _2235 = _2231;\n    }\n    else\n    {\n        _2235 = (conv.y * conv.z) / (conv.z - (_2231 * (conv.z - conv.y)));\n    }\n    return _2235;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel_turn(vec2 d)\n{\n    return vec2((d.x * (-0.737368881702423095703125)) - (d.y * 0.675490319728851318359375), (d.y * (-0.737368881702423095703125)) + (d.x * 0.675490319728851318359375));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2281 = fa_shadow_noise() * 6.283185482025146484375;\n    vec2 _2287 = vec2(cos(_2281), sin(_2281));\n    vec2 dir = _2287;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2296;\n        if (k < 0.0)\n        {\n            _2296 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2296 = k;\n        }\n        float _2315 = clamp((_2296 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            float _2334 = sqrt((float(i) + 0.5) * 0.0625) * _2315;\n            vec2 param_3 = uv + (dir * (fa_shadows[26].zw * _2334));\n            vec4 param_4 = rect;\n            vec3 param_5 = conv;\n            float _2348 = fa_shadow_fetch(param_3, param_4, param_5);\n            if (_2348 < (zr - (_2334 * plane)))\n            {\n                sum += _2348;\n                cnt += 1.0;\n            }\n            vec2 param_6 = dir;\n            dir = fa_shadow_vogel_turn(param_6);\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2376 = sum / cnt;\n        float _2386;\n        if (k < 0.0)\n        {\n            _2386 = (-k) / max(_2376, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2386 = k;\n        }\n        radius = clamp(((max(zr - _2376, 0.0) * unit) * _2386) / texel_m, 1.5, 16.0);\n        dir = _2287;\n    }\n    float lit = 0.0;\n    int _2412 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2412; i_1++)\n    {\n        float _2431 = sqrt((float(i_1) + 0.5) / float(_2412)) * radius;\n        vec2 param_7 = uv + (dir * (fa_shadows[26].zw * _2431));\n        vec4 param_8 = rect;\n        vec3 param_9 = conv;\n        lit += float((zr - (_2431 * plane)) <= fa_shadow_fetch(param_7, param_8, param_9));\n        vec2 param_10 = dir;\n        dir = fa_shadow_vogel_turn(param_10);\n    }\n    return lit / float(_2412);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2636 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2643;\n    if (!_2636)\n    {\n        _2643 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2643 = _2636;\n    }\n    if (_2643)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2656 = fa_light_texel(param);\n    float _2657 = _2656.x;\n    if (_2657 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2666 = int(_2657 + 0.5);\n    int param_1 = _2666;\n    vec4 _2670 = fa_light_texel(param_1);\n    int param_2 = _2666 + 1;\n    vec4 _2675 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2678 = _2670.y;\n    if (_2678 > 0.0)\n    {\n        float _2695 = 1.0 - smoothstep(0.75 * _2678, _2678, length(world - fa_shadows[27].xyz));\n        fade = _2695;\n        if (_2695 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2670.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2719 = (_2666 + 2) + (face * 6);\n    int param_4 = _2719;\n    int param_5 = _2719 + 1;\n    int param_6 = _2719 + 3;\n    vec4 _2733 = fa_light_texel(param_6);\n    int param_7 = _2719 + 4;\n    vec4 _2738 = fa_light_texel(param_7);\n    int param_8 = _2719 + 5;\n    vec4 _2743 = fa_light_texel(param_8);\n    float _2755 = _2743.x * max(dot(_2733, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2760 = clamp(dot(n, l), 0.0, 1.0);\n    float _2783 = clamp(dot(n, _2733.xyz), -1.0, 1.0);\n    float _2802 = min(sqrt(1.0 - (_2783 * _2783)) / max(abs(dot(n, world - lpos)) / max(dot(_2733, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2805 = _2675.y;\n    float _2807;\n    if (_2805 > 0.0)\n    {\n        _2807 = _2805;\n    }\n    else\n    {\n        _2807 = 1.5 * _2755;\n    }\n    vec4 _2827 = vec4(world + (n * (_2807 * sqrt(1.0 - (_2760 * _2760)))), 1.0);\n    float _2831 = dot(_2733, _2827);\n    float _2834 = _2743.y;\n    if (_2831 < _2834)\n    {\n        return 1.0;\n    }\n    vec2 _2849 = vec2(dot(fa_light_texel(param_4), _2827), dot(fa_light_texel(param_5), _2827)) / vec2(_2831);\n    float _2851 = _2849.x;\n    bool _2854 = _2851 < _2738.x;\n    bool _2863;\n    if (!_2854)\n    {\n        _2863 = _2851 > _2738.z;\n    }\n    else\n    {\n        _2863 = _2854;\n    }\n    bool _2872;\n    if (!_2863)\n    {\n        _2872 = _2849.y < _2738.y;\n    }\n    else\n    {\n        _2872 = _2863;\n    }\n    bool _2881;\n    if (!_2872)\n    {\n        _2881 = _2849.y > _2738.w;\n    }\n    else\n    {\n        _2881 = _2872;\n    }\n    if (_2881)\n    {\n        return 1.0;\n    }\n    float _2887 = _2675.x;\n    float _2889;\n    if (_2887 > 0.0)\n    {\n        _2889 = _2887;\n    }\n    else\n    {\n        _2889 = 1.5 * _2755;\n    }\n    vec2 param_9 = _2849;\n    vec4 param_10 = _2738;\n    float param_11 = _2831 - (_2889 * (1.0 + (0.5 * _2802)));\n    float param_12 = _2755;\n    float param_13 = 1.0;\n    float param_14 = _2743.z * 0.25;\n    float param_15 = (_2755 * min(_2802, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2834, _2743.z);\n    int param_17 = int(_2670.z + 0.5);\n    float param_18 = _2670.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2174;\n    if (i == 0)\n    {\n        _2174 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2190;\n        if (i == 1)\n        {\n            _2190 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2198;\n            if (i == 2)\n            {\n                _2198 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2198 = fa_shadows[24].w;\n            }\n            _2190 = _2198;\n        }\n        _2174 = _2190;\n    }\n    return _2174;\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2477 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2482 = clamp(dot(n, l), 0.0, 1.0);\n    float _2488 = sqrt(1.0 - (_2482 * _2482));\n    float _2496 = min(_2488 / max(_2482, 0.20000000298023223876953125), 4.0);\n    float _2501;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2501 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2501 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2526 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2501 * _2488)), 1.0);\n    float _2533 = _2526.x;\n    bool _2536 = _2533 < fa_shadows[ci * 1 + 16].x;\n    bool _2545;\n    if (!_2536)\n    {\n        _2545 = _2533 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2545 = _2536;\n    }\n    bool _2554;\n    if (!_2545)\n    {\n        _2554 = _2526.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2554 = _2545;\n    }\n    bool _2563;\n    if (!_2554)\n    {\n        _2563 = _2526.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2563 = _2554;\n    }\n    bool _2570;\n    if (!_2563)\n    {\n        _2570 = _2526.z > 1.0;\n    }\n    else\n    {\n        _2570 = _2563;\n    }\n    if (_2570)\n    {\n        return -1.0;\n    }\n    float _2578;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2578 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2578 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2526.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2526.z - ((_2578 * (1.0 + (0.5 * _2496))) / _2477);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2477;\n    float param_5 = _2477 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2496, 3.0)) * 0.5) / _2477;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2956 = int(fa_shadows[25].x + 0.5);\n    if (_2956 < 1)\n    {\n        return 1.0;\n    }\n    float _2971 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2956 - 1;\n    if (_2971 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2983 = _2956 > 1;\n    bool _2990;\n    if (_2983)\n    {\n        _2990 = _2971 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2990 = _2983;\n    }\n    if (_2990)\n    {\n        ci = 1;\n    }\n    bool _2994 = _2956 > 2;\n    bool _3001;\n    if (_2994)\n    {\n        _3001 = _2971 > fa_shadows[24].y;\n    }\n    else\n    {\n        _3001 = _2994;\n    }\n    if (_3001)\n    {\n        ci = 2;\n    }\n    bool _3005 = _2956 > 3;\n    bool _3012;\n    if (_3005)\n    {\n        _3012 = _2971 > fa_shadows[24].z;\n    }\n    else\n    {\n        _3012 = _3005;\n    }\n    if (_3012)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    float s2 = -1.0;\n    float t = 0.0;\n    int _3023 = min(_2956, 4);\n    float _3064;\n    for (int c = ci; c < _3023; c++)\n    {\n        int param_1 = c;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _3043 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        if (s >= 0.0)\n        {\n            s2 = _3043;\n            break;\n        }\n        if (_3043 < 0.0)\n        {\n            continue;\n        }\n        s = _3043;\n        ci = c;\n        if (fa_shadows[25].y > 0.0)\n        {\n            if (ci > 0)\n            {\n                int param_5 = ci - 1;\n                _3064 = fa_shadow_split_at(param_5);\n            }\n            else\n            {\n                _3064 = fa_shadows[28].w;\n            }\n            int param_6 = ci;\n            float _3083 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _3064, 9.9999997473787516355514526367188e-05);\n            int param_7 = ci;\n            t = clamp((_2971 - (fa_shadow_split_at(param_7) - _3083)) / _3083, 0.0, 1.0);\n        }\n        if (t <= 0.0)\n        {\n            break;\n        }\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (t > 0.0)\n    {\n        float _3115;\n        if ((ci + 1) < _2956)\n        {\n            _3115 = (s2 < 0.0) ? s : s2;\n        }\n        else\n        {\n            _3115 = 1.0;\n        }\n        s = mix(s, _3115, t);\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _4756 = fa_mesh_fs_params[24].x < 0.5;\n    bool _4763;\n    if (!_4756)\n    {\n        _4763 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _4763 = _4756;\n    }\n    if (_4763)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _4776 = fa_light_texel(param);\n    float _4777 = _4776.y;\n    float len = _4777;\n    if (_4777 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4789 = length(world - fa_mesh_fs_params[0].xyz);\n    float _4799 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _4789);\n    if (_4799 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _4805 = len;\n    float _4808 = min(_4805, 0.89999997615814208984375 * dist);\n    len = _4808;\n    float _4813 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _4789);\n    float _4818 = _4813 + (0.5 * _4808);\n    vec3 _4824 = world + (gn * _4813);\n    float _4826 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4890;\n    for (int k = 0; k < 12; k++)\n    {\n        float _4841 = (float(k) + _4826) * 0.083333335816860198974609375;\n        vec3 _4849 = _4824 + (l * (_4841 * len));\n        vec4 _4855 = vec4(_4849, 1.0);\n        float _4861 = dot(fa_mesh_fs_params[28], _4855);\n        if (_4861 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4881 = vec2(dot(fa_mesh_fs_params[26], _4855), dot(fa_mesh_fs_params[27], _4855)) / vec2(_4861);\n        float _4885 = _4881.x * 0.5;\n        float _4886 = _4885 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4890 = (_4881.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4890 = 0.5 - (_4881.y * 0.5);\n        }\n        bool _4906 = _4886 < 0.0;\n        bool _4913;\n        if (!_4906)\n        {\n            _4913 = _4886 >= 1.0;\n        }\n        else\n        {\n            _4913 = _4906;\n        }\n        bool _4920;\n        if (!_4913)\n        {\n            _4920 = _4890 < 0.0;\n        }\n        else\n        {\n            _4920 = _4913;\n        }\n        bool _4927;\n        if (!_4920)\n        {\n            _4927 = _4890 >= 1.0;\n        }\n        else\n        {\n            _4927 = _4920;\n        }\n        if (_4927)\n        {\n            break;\n        }\n        vec4 _4954 = texelFetch(fa_screen_tex_fa_shadow_smp, clamp(ivec2(vec2(_4886, _4890) * fa_mesh_fs_params[24].zw), ivec2(0), ivec2(fa_mesh_fs_params[24].zw) - ivec2(1)), 0);\n        if (_4954.w < 0.5)\n        {\n            continue;\n        }\n        float _4973 = (dot(fa_mesh_fs_params[29].xyz, _4849) + fa_mesh_fs_params[29].w) - _4954.x;\n        if ((_4973 > _4813) && (_4973 < _4818))\n        {\n            occ = max(occ, (1.0 - (_4841 * _4841)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4886, 0.5 - _4885), min(_4890, 1.0 - _4890))));\n        }\n    }\n    return 1.0 - (occ * _4799);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _5076 = fa_baked_keep(param);\n    if (_5076 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _5102 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _6971 = _5102.color;\n    float _6972 = _5102.attenuation;\n    float _6973 = _5102.shadow;\n    bool _5105 = _5102.type == 0;\n    if (_5105 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _5102.direction;\n        float _5116 = fa_shadow_factor(param_5, param_6);\n        _6973 = _5116;\n        _6971 *= _5116;\n    }\n    else\n    {\n        bool _5127 = _5102.type != 0;\n        bool _5133;\n        if (_5127)\n        {\n            _5133 = _6972 > 0.0;\n        }\n        else\n        {\n            _5133 = _5127;\n        }\n        if (_5133)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _5102.direction;\n            float _5152 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _6973 = _5152;\n            _6971 *= _5152;\n        }\n    }\n    bool _5162 = fa_mesh_fs_params[24].x > 0.5;\n    bool _5168;\n    if (_5162)\n    {\n        _5168 = _6972 > 0.0;\n    }\n    else\n    {\n        _5168 = _5162;\n    }\n    if (_5168)\n    {\n        float _5175;\n        if (_5105)\n        {\n            _5175 = 1000000000.0;\n        }\n        else\n        {\n            _5175 = _5102._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _5102.direction;\n        float param_18 = _5175;\n        float _5193 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _6973 *= _5193;\n        _6971 *= _5193;\n    }\n    float _5206 = _6972;\n    float _5207 = _5206 * _5076;\n    _6972 = _5207;\n    vec3 _5211 = _6971;\n    vec3 _5212 = _5211 * _5076;\n    _6971 = _5212;\n    return LightSample(_5102.direction, _5212, _5207, _6973, _5102._distance, _5102.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3143 = int(fa_shadows[25].x + 0.5);\n    float _3153 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3158 = _3143 > 0;\n    bool _3167;\n    if (_3158)\n    {\n        int param = _3143 - 1;\n        _3167 = _3153 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3167 = _3158;\n    }\n    if (_3167)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3173 = _3143 > 1;\n        bool _3180;\n        if (_3173)\n        {\n            _3180 = _3153 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3180 = _3173;\n        }\n        if (_3180)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3186 = _3143 > 2;\n        bool _3193;\n        if (_3186)\n        {\n            _3193 = _3153 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3193 = _3186;\n        }\n        if (_3193)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3199 = _3143 > 3;\n        bool _3206;\n        if (_3199)\n        {\n            _3206 = _3153 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3206 = _3199;\n        }\n        if (_3206)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _6656 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _6656 = -_6656;\n    }\n    vec3 _6278 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _6656, fa_world_tangent, fa_uv, fa_vertex_color, _6278, gl_FrontFacing);\n    Surface _6286 = fa_standard_surface(param_1);\n    vec3 _6695 = _6286.albedo;\n    float _6696 = _6286.alpha;\n    vec3 _6697 = _6286.normal;\n    float _6698 = _6286.metallic;\n    float _6699 = _6286.roughness;\n    float _6700 = _6286.occlusion;\n    vec3 _6701 = _6286.emission;\n    float _6702 = _6286.clearcoat;\n    float _6703 = _6286.clearcoat_roughness;\n    vec3 _6704 = _6286.sheen_color;\n    float _6705 = _6286.sheen_roughness;\n    float _6706 = _6286.anisotropy;\n    float _6707 = _6286.anisotropy_rotation;\n    float _6708 = _6286.specular;\n    float _6709 = _6286.ior;\n    vec3 _6710 = _6286.specular_color;\n    float _6711 = _6286.transmission;\n    float _6712 = _6286.thickness;\n    vec3 _6713 = _6286.attenuation_color;\n    float _6714 = _6286.attenuation_distance;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _6656, fa_world_tangent, fa_uv, fa_vertex_color, _6278, gl_FrontFacing);\n    Surface param_3 = _6286;\n    surface(param_2, param_3);\n    _6695 = param_3.albedo;\n    _6696 = param_3.alpha;\n    _6697 = param_3.normal;\n    _6698 = param_3.metallic;\n    _6699 = param_3.roughness;\n    _6700 = param_3.occlusion;\n    _6701 = param_3.emission;\n    _6702 = param_3.clearcoat;\n    _6703 = param_3.clearcoat_roughness;\n    _6704 = param_3.sheen_color;\n    _6705 = param_3.sheen_roughness;\n    _6706 = param_3.anisotropy;\n    _6707 = param_3.anisotropy_rotation;\n    _6708 = param_3.specular;\n    _6709 = param_3.ior;\n    _6710 = param_3.specular_color;\n    _6711 = param_3.transmission;\n    _6712 = param_3.thickness;\n    _6713 = param_3.attenuation_color;\n    _6714 = param_3.attenuation_distance;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _6656;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _6695 = param_6;\n    _6697 = param_7;\n    fa_lod_dither();\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _6695;\n    }\n    else\n    {\n        vec3 _6326 = _6697;\n        vec3 _6327 = normalize(_6326);\n        _6697 = _6327;\n        vec3 param_8 = _6327;\n        SurfaceInput param_9 = SurfaceInput(fa_world_pos, _6656, fa_world_tangent, fa_uv, fa_vertex_color, _6278, gl_FrontFacing);\n        Surface param_10 = Surface(_6695, _6696, _6697, _6698, _6699, _6700, _6701, _6702, _6703, _6704, _6705, _6706, _6707, _6708, _6709, _6710, _6711, _6712, _6713, _6714);\n        vec3 param_11 = fa_indirect_diffuse(param_8);\n        vec3 lit = ambient(param_9, param_10, param_11);\n        int _6346 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _6346; ln++)\n        {\n            int param_12 = ln;\n            int _6359 = fa_cl_light(param_12);\n            int param_13 = _6359;\n            if (fa_baked_keep(param_13) <= 0.0)\n            {\n                continue;\n            }\n            int param_14 = _6359;\n            vec3 param_15 = fa_world_pos;\n            vec3 param_16 = _6656;\n            LightSample _6375 = fa_light_shadowed(param_14, param_15, param_16);\n            SurfaceInput param_17 = SurfaceInput(fa_world_pos, _6656, fa_world_tangent, fa_uv, fa_vertex_color, _6278, gl_FrontFacing);\n            Surface param_18 = Surface(_6695, _6696, _6697, _6698, _6699, _6700, _6701, _6702, _6703, _6704, _6705, _6706, _6707, _6708, _6709, _6710, _6711, _6712, _6713, _6714);\n            LightSample param_19 = _6375;\n            lit += light(param_17, param_18, param_19);\n        }\n        result = lit;\n    }\n    vec3 _6390 = result;\n    vec3 _6391 = _6390 + _6701;\n    result = _6391;\n    vec3 param_20 = _6391;\n    vec3 param_21 = fa_world_pos;\n    result = fa_shadow_debug(param_20, param_21);\n    bool _6400 = fa_mesh_fs_params[7].w > 0.0;\n    bool _6407;\n    if (!_6400)\n    {\n        _6407 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _6407 = _6400;\n    }\n    if (_6407)\n    {\n        vec3 _6416 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _6422 = dot(_6416, fa_mesh_fs_params[9].xyz);\n        bool _6426 = fa_mesh_fs_params[9].w > 0.5;\n        float _6427;\n        if (_6426)\n        {\n            _6427 = _6422;\n        }\n        else\n        {\n            _6427 = length(_6416);\n        }\n        float _6439 = _6427 - fa_mesh_fs_params[8].x;\n        if (_6439 > 0.0)\n        {\n            float _6448 = fa_mesh_fs_params[7].w * _6439;\n            float tau = _6448 * _6448;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _6464;\n                if (_6426)\n                {\n                    _6464 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _6422);\n                }\n                else\n                {\n                    _6464 = fa_mesh_fs_params[0].y;\n                }\n                float _6485 = mix(_6464, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _6427, 0.0, 1.0));\n                float _6489 = fa_world_pos.y - _6485;\n                float _6494 = _6485 - fa_mesh_fs_params[8].z;\n                float _6499 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _6502 = _6494 <= 0.0;\n                bool _6503 = !_6502;\n                bool _6509;\n                if (_6503)\n                {\n                    _6509 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6509 = _6502;\n                }\n                float _6510;\n                if (_6509)\n                {\n                    _6510 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _6510 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _6494, 80.0));\n                }\n                bool _6537;\n                if (_6503)\n                {\n                    _6537 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6537 = _6502;\n                }\n                float _6538;\n                if (_6537)\n                {\n                    _6538 = fa_mesh_fs_params[8].y * _6494;\n                }\n                else\n                {\n                    _6538 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6494, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _6563 = _6499 <= 0.0;\n                bool _6570;\n                if (!_6563)\n                {\n                    _6570 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _6570 = _6563;\n                }\n                float _6571;\n                if (_6570)\n                {\n                    _6571 = fa_mesh_fs_params[8].y * _6499;\n                }\n                else\n                {\n                    _6571 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _6499, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _6598;\n                if (abs(_6489) < 0.001000000047497451305389404296875)\n                {\n                    _6598 = _6510;\n                }\n                else\n                {\n                    _6598 = (_6571 - _6538) / _6489;\n                }\n                tau += (_6439 * max(_6598, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _6696);\n}\n\n",
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
            "inst_name": "_450",
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
            "inst_name": "_2184",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _267 = fa_tex_fix(param_2, param_3);\n    vec4 _868 = base_t;\n    _868.x = _267.x;\n    _868.y = _267.y;\n    _868.z = _267.z;\n    base_t = _868;\n    vec4 _283 = (_868 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _823 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _317 = fa_tex_fix(param_6, param_7);\n        vec3 _321 = (_317 * 2.0) - vec3(1.0);\n        vec2 _326 = _321.xy * fa_mesh_fs_params[6].x;\n        vec3 _876 = _321;\n        _876.x = _326.x;\n        _876.y = _326.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _876;\n        _823 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _355 = fa_tex_fix(param_12, param_13);\n    vec4 _879 = mrt;\n    _879.x = _355.x;\n    _879.y = _355.y;\n    _879.z = _355.z;\n    mrt = _879;\n    vec4 _385 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _427 = fa_tex_fix(param_20, param_21);\n    float _828 = fa_mesh_fs_params[20].x;\n    float _829 = fa_mesh_fs_params[20].y;\n    float _832 = fa_mesh_fs_params[20].z;\n    float _831 = fa_mesh_fs_params[21].w;\n    float _834 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _828 *= _397.y;\n            _829 *= _397.z;\n            _831 *= _385.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _832 *= mrt.x;\n            _834 *= mrt.w;\n        }\n    }\n    return Surface(_283.xyz, _283.w, _823, clamp(fa_mesh_fs_params[5].x * _355.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _355.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_397.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _427), _828, _829, fa_mesh_fs_params[21].xyz, _831, _832, fa_mesh_fs_params[20].w, _834, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _718 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _718 = -_718;\n    }\n    vec3 _579 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface _584 = fa_standard_surface(param);\n    vec3 _742 = _584.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _742 = param_2.normal;\n    fa_lod_dither();\n    vec3 _595 = normalize(_742);\n    vec3 _610 = normalize(vec3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    vec2 e = _610.xy / vec2((abs(_610.x) + abs(_610.y)) + abs(_622));\n    if (_622 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_129",
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
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n    float transmission;\n    float thickness;\n    vec3 attenuation_color;\n    float attenuation_distance;\n};\n\nuniform vec4 fa_mesh_fs_params[53];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _218 = fa_linear_to_srgb(param);\n        c = _218;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _227 = fa_srgb_to_linear(param_1);\n            c = _227;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _58;\n    if (i.front_facing)\n    {\n        _58 = i.world_normal;\n    }\n    else\n    {\n        _58 = -i.world_normal;\n    }\n    vec3 _83 = normalize(i.world_tangent.xyz - (_58 * dot(_58, i.world_tangent.xyz)));\n    vec3 _111 = normalize(((_83 * m.x) + ((cross(_58, _83) * i.world_tangent.w) * m.y)) + (_58 * m.z));\n    vec3 _114;\n    if (i.front_facing)\n    {\n        _114 = _111;\n    }\n    else\n    {\n        _114 = -_111;\n    }\n    return _114;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _267 = fa_tex_fix(param_2, param_3);\n    vec4 _868 = base_t;\n    _868.x = _267.x;\n    _868.y = _267.y;\n    _868.z = _267.z;\n    base_t = _868;\n    vec4 _283 = (_868 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _823 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _317 = fa_tex_fix(param_6, param_7);\n        vec3 _321 = (_317 * 2.0) - vec3(1.0);\n        vec2 _326 = _321.xy * fa_mesh_fs_params[6].x;\n        vec3 _876 = _321;\n        _876.x = _326.x;\n        _876.y = _326.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _876;\n        _823 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _355 = fa_tex_fix(param_12, param_13);\n    vec4 _879 = mrt;\n    _879.x = _355.x;\n    _879.y = _355.y;\n    _879.z = _355.z;\n    mrt = _879;\n    vec4 _385 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _385.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _397 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _427 = fa_tex_fix(param_20, param_21);\n    float _828 = fa_mesh_fs_params[20].x;\n    float _829 = fa_mesh_fs_params[20].y;\n    float _832 = fa_mesh_fs_params[20].z;\n    float _831 = fa_mesh_fs_params[21].w;\n    float _834 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _828 *= _397.y;\n            _829 *= _397.z;\n            _831 *= _385.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _832 *= mrt.x;\n            _834 *= mrt.w;\n        }\n    }\n    return Surface(_283.xyz, _283.w, _823, clamp(fa_mesh_fs_params[5].x * _355.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _355.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_397.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _427), _828, _829, fa_mesh_fs_params[21].xyz, _831, _832, fa_mesh_fs_params[20].w, _834, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz, fa_mesh_fs_params[30].x, fa_mesh_fs_params[30].y, fa_mesh_fs_params[31].xyz, fa_mesh_fs_params[30].z);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid fa_lod_dither()\n{\n    if (fa_mesh_fs_params[52].w != 0.0)\n    {\n        float _151 = fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n        bool _154;\n        if (fa_mesh_fs_params[52].w > 0.0)\n        {\n            _154 = _151 >= fa_mesh_fs_params[52].w;\n        }\n        else\n        {\n            _154 = _151 < (-fa_mesh_fs_params[52].w);\n        }\n        if (_154)\n        {\n            discard;\n        }\n    }\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _718 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _718 = -_718;\n    }\n    vec3 _579 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface _584 = fa_standard_surface(param);\n    vec3 _742 = _584.normal;\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _718, fa_world_tangent, fa_uv, fa_vertex_color, _579, gl_FrontFacing);\n    Surface param_2 = _584;\n    surface(param_1, param_2);\n    _742 = param_2.normal;\n    fa_lod_dither();\n    vec3 _595 = normalize(_742);\n    vec3 _610 = normalize(vec3(dot(fa_pre_r0, _595), dot(fa_pre_r1, _595), dot(fa_pre_r2, _595)));\n    float _622 = _610.z;\n    vec2 e = _610.xy / vec2((abs(_610.x) + abs(_610.y)) + abs(_622));\n    if (_622 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "inst_name": "_129",
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
