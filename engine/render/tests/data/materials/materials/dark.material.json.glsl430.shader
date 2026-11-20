{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "550ff47e6dc7e71192661fb1e526df6e96f66de981c805742262dd122b44bf86",
  "slang": "glsl430",
  "params": [],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _267 = _160.world_pos;\n    fa_world_pos = _267;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_267, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1318 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1325;\n    if (!_1318)\n    {\n        _1325 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1325 = _1318;\n    }\n    bool _1333;\n    if (!_1325)\n    {\n        _1333 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1333 = _1325;\n    }\n    bool _1340;\n    if (!_1333)\n    {\n        _1340 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1340 = _1333;\n    }\n    bool _1347;\n    if (!_1340)\n    {\n        _1347 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1347 = _1340;\n    }\n    if (_1347)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1357 = vec4(world_pos, 1.0);\n    float _1363 = dot(fa_mesh_fs_params[16], _1357);\n    if (!(_1363 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1385 = vec2(dot(fa_mesh_fs_params[14], _1357), dot(fa_mesh_fs_params[15], _1357)) / vec2(_1363);\n    int _1389 = int(fa_mesh_fs_params[18].x);\n    int _1393 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1393) + clamp(int(floor(((_1385.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1393 - 1)) * _1389)) + clamp(int(floor(((_1385.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1389 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1469 = fa_cluster_texel(param);\n    return ivec2(int(_1469.x), int(_1469.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3528 = fa_cluster_lookup(param);\n    fa_cl_slot = _3528.x;\n    fa_cl_local = _3528.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3733 = fa_linear_to_srgb(param);\n        c = _3733;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3741 = fa_srgb_to_linear(param_1);\n            c = _3741;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _272;\n    if (i.front_facing)\n    {\n        _272 = i.world_normal;\n    }\n    else\n    {\n        _272 = -i.world_normal;\n    }\n    vec3 _296 = normalize(i.world_tangent.xyz - (_272 * dot(_272, i.world_tangent.xyz)));\n    vec3 _323 = normalize(((_296 * m.x) + ((cross(_272, _296) * i.world_tangent.w) * m.y)) + (_272 * m.z));\n    vec3 _326;\n    if (i.front_facing)\n    {\n        _326 = _323;\n    }\n    else\n    {\n        _326 = -_323;\n    }\n    return _326;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3772 = fa_tex_fix(param_2, param_3);\n    vec4 _4838 = base_t;\n    _4838.x = _3772.x;\n    _4838.y = _3772.y;\n    _4838.z = _3772.z;\n    base_t = _4838;\n    vec4 _3786 = (_4838 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4690 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3818 = fa_tex_fix(param_6, param_7);\n        vec3 _3821 = (_3818 * 2.0) - vec3(1.0);\n        vec2 _3826 = _3821.xy * fa_mesh_fs_params[6].x;\n        vec3 _4846 = _3821;\n        _4846.x = _3826.x;\n        _4846.y = _3826.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4846;\n        _4690 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3854 = fa_tex_fix(param_12, param_13);\n    vec4 _4849 = mrt;\n    _4849.x = _3854.x;\n    _4849.y = _3854.y;\n    _4849.z = _3854.z;\n    mrt = _4849;\n    vec4 _3882 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3882.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3893 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3923 = fa_tex_fix(param_20, param_21);\n    float _4695 = fa_mesh_fs_params[20].x;\n    float _4696 = fa_mesh_fs_params[20].y;\n    float _4699 = fa_mesh_fs_params[20].z;\n    float _4698 = fa_mesh_fs_params[21].w;\n    float _4701 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4695 *= _3893.y;\n            _4696 *= _3893.z;\n            _4698 *= _3882.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4699 *= mrt.x;\n            _4701 *= mrt.w;\n        }\n    }\n    return Surface(_3786.xyz, _3786.w, _4690, clamp(fa_mesh_fs_params[5].x * _3854.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3854.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3893.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3923), _4695, _4696, fa_mesh_fs_params[21].xyz, _4698, _4699, fa_mesh_fs_params[20].w, _4701, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1549 = rect.zw - rect.xy;\n    vec2 _1553 = _1549 * atlas;\n    vec2 _1557 = ddx * _1553;\n    vec2 _1561 = ddy * _1553;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1549), clamp(0.5 * log2(max(max(dot(_1557, _1557), dot(_1561, _1561)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1594 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1601;\n    if (!_1594)\n    {\n        _1601 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1601 = _1594;\n    }\n    if (_1601)\n    {\n        return;\n    }\n    vec3 _1607 = dFdx(world_pos);\n    vec3 _1610 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1614 = fa_cluster_texel(param);\n    int _1618 = int(_1614.w);\n    if (_1618 < 1)\n    {\n        return;\n    }\n    int _1628 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1628;\n    vec4 _1632 = fa_light_texel(param_1);\n    vec2 _1635 = _1632.yz;\n    int _1639 = int(_1632.w);\n    int param_2 = _1628 + 1;\n    vec4 _1644 = fa_light_texel(param_2);\n    float _1645 = _1644.x;\n    int _1651 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1655 = int(_1614.z);\n    vec3 _1920;\n    for (int k = 0; k < _1618; k++)\n    {\n        int _1668 = _1655 + k;\n        int param_3 = _1639 + (_1668 >> 2);\n        int _1685 = (_1628 + 2) + (int(fa_light_texel(param_3)[_1668 & 3]) * 7);\n        int param_4 = _1685 + 6;\n        vec4 _1690 = fa_light_texel(param_4);\n        if (((int(_1690.w + 0.5) >> _1651) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1685;\n        vec4 _1705 = fa_light_texel(param_5);\n        int param_6 = _1685 + 1;\n        vec4 _1710 = fa_light_texel(param_6);\n        int param_7 = _1685 + 2;\n        vec4 _1715 = fa_light_texel(param_7);\n        vec3 _1718 = _1705.xyz;\n        float _1723 = dot(_1718, world_pos) + _1705.w;\n        vec3 _1725 = _1710.xyz;\n        float _1730 = dot(_1725, world_pos) + _1710.w;\n        vec3 _1732 = _1715.xyz;\n        float _1737 = dot(_1732, world_pos) + _1715.w;\n        bool _1742 = abs(_1723) > 0.5;\n        bool _1750;\n        if (!_1742)\n        {\n            _1750 = abs(_1730) > 0.5;\n        }\n        else\n        {\n            _1750 = _1742;\n        }\n        bool _1758;\n        if (!_1750)\n        {\n            _1758 = abs(_1737) > 0.5;\n        }\n        else\n        {\n            _1758 = _1750;\n        }\n        if (_1758)\n        {\n            continue;\n        }\n        float _1773 = clamp(dot(geo_normal, normalize(_1732)) * _1690.z, 0.0, 1.0);\n        if (_1773 <= 0.0)\n        {\n            continue;\n        }\n        float _1793 = (clamp((0.5 - abs(_1737)) * 10.0, 0.0, 1.0) * _1773) * _1690.x;\n        vec2 _1801 = vec2(_1723 + 0.5, 0.5 - _1730);\n        vec2 _1811 = vec2(dot(_1718, _1607), dot(_1725, _1607));\n        vec2 _1821 = vec2(dot(_1718, _1610), dot(_1725, _1610));\n        int param_8 = _1685 + 5;\n        vec4 _1826 = fa_light_texel(param_8);\n        int param_9 = _1685 + 3;\n        vec4 _1831 = fa_light_texel(param_9);\n        int param_10 = _1685 + 4;\n        vec4 _1836 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1826.xyz;\n        bool _1846 = _1831.z > _1831.x;\n        if (_1846)\n        {\n            vec4 param_11 = _1831;\n            vec2 param_12 = _1801;\n            vec2 param_13 = _1635;\n            vec2 param_14 = _1811;\n            vec2 param_15 = _1821;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1645 > 0.5) && (_1645 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1872 = fa_dc_to_linear(param_16);\n                vec4 _4770 = tx;\n                _4770.x = _1872.x;\n                _4770.y = _1872.y;\n                _4770.z = _1872.z;\n                tx = _4770;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1793 * tex_a) * _1826.w, 0.0, 1.0)));\n        if (_1836.z > _1836.x)\n        {\n            vec4 param_17 = _1836;\n            vec2 param_18 = _1801;\n            vec2 param_19 = _1635;\n            vec2 param_20 = _1811;\n            vec2 param_21 = _1821;\n            vec4 _1916 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1645 > 1.5)\n            {\n                vec3 param_22 = _1916.xyz;\n                vec3 _1926 = fa_dc_to_srgb(param_22);\n                _1920 = _1926;\n            }\n            else\n            {\n                _1920 = _1916.xyz;\n            }\n            vec3 _1935 = (_1920 * 2.0) - vec3(1.0);\n            vec2 _1940 = _1935.xy * _1690.y;\n            vec3 _1962 = (normalize(_1718) * _1940.x) + (normalize(_1725) * _1940.y);\n            vec3 _1965 = normalize(normal);\n            normal = normalize(mix(_1965, normalize((_1965 * max(_1935.z, 0.0500000007450580596923828125)) + (_1962 - (_1965 * dot(_1965, _1962)))), vec3(clamp(_1793 * (_1846 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3160 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3160;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3498;\n    if (fa_lm.z > 0.5)\n    {\n        _3498 = 0.0;\n    }\n    else\n    {\n        _3498 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _3509 = _3498 < 1.0;\n    bool _3515;\n    if (_3509)\n    {\n        int param = li;\n        _3515 = fa_light_baked(param);\n    }\n    else\n    {\n        _3515 = _3509;\n    }\n    return _3515 ? _3498 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _568 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _581 = (c - (ru * hx)) - p;\n        vec3 _587 = ru * (2.0 * hx);\n        float _593 = max(dot(_587, _587), 9.9999999392252902907785028219223e-09);\n        float _597 = dot(_581, _587);\n        float t = clamp((-_597) / _593, 0.0, 1.0);\n        if (_568)\n        {\n            float _612 = dot(r, _587);\n            float _618 = _593 - (_612 * _612);\n            if (abs(_618) > (9.9999997473787516355514526367188e-06 * _593))\n            {\n                t = clamp(((dot(r, _581) * _612) - _597) / _618, 0.0, 1.0);\n            }\n        }\n        return (p + _581) + (_587 * t);\n    }\n    vec3 q = p;\n    float _650 = dot(r, axis);\n    bool _658;\n    if (_568)\n    {\n        _658 = abs(_650) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _658 = _568;\n    }\n    if (_658)\n    {\n        float _668 = dot(c - p, axis) / _650;\n        if (_668 > 0.0)\n        {\n            q = p + (r * _668);\n        }\n    }\n    vec3 _681 = q - c;\n    vec2 xy = vec2(dot(_681, ru), dot(_681, uu));\n    if (shape > 0.5)\n    {\n        float _696 = length(xy);\n        if (_696 > hx)\n        {\n            xy *= (hx / _696);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _338 = abs(d);\n    float _340 = _338.x;\n    float _342 = _338.y;\n    bool _343 = _340 >= _342;\n    bool _351;\n    if (_343)\n    {\n        _351 = _340 >= _338.z;\n    }\n    else\n    {\n        _351 = _343;\n    }\n    int _352;\n    if (_351)\n    {\n        _352 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _367;\n        if (_342 >= _338.z)\n        {\n            _367 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _367 = (d.z > 0.0) ? 4 : 5;\n        }\n        _352 = _367;\n    }\n    return _352;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _488 = dot(d, right);\n    float _492 = dot(d, up);\n    float _503;\n    if (((_488 * _488) + (_492 * _492)) > 1.0000000133514319600180897396058e-10)\n    {\n        _503 = atan(_492, _488) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _503 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_503 - floor(_503)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _734 = fa_light_base(param);\n    bool _738 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _734;\n    vec4 _742 = fa_light_texel(param_1);\n    int param_2 = _734 + 1;\n    vec4 _747 = fa_light_texel(param_2);\n    float _750 = _747.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _762 = _738 && (_750 > 2.5);\n    fa_light_is_area = _762;\n    bool _764 = _750 < 0.5;\n    vec3 l;\n    if (_764)\n    {\n        l = normalize(_742.xyz);\n        if (_738)\n        {\n            int param_3 = _734 + 6;\n            vec4 _778 = fa_light_texel(param_3);\n            if (_778.z > 0.5)\n            {\n                int param_4 = _734 + 4;\n                vec4 _788 = fa_light_texel(param_4);\n                int param_5 = _734 + 5;\n                vec4 _793 = fa_light_texel(param_5);\n                vec2 param_6 = _778.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _788.xyz) * _788.w, (-dot(world_pos, _793.xyz)) * _793.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _823 = _742.xyz;\n        vec3 _825 = _823 - world_pos;\n        vec3 to_light = _825;\n        float _828 = length(_825);\n        float reach = _828;\n        bool front = true;\n        if (_762)\n        {\n            int param_8 = _734 + 7;\n            reach = max(_828 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _734 + 4;\n            vec4 _852 = fa_light_texel(param_9);\n            int param_10 = _734 + 5;\n            vec4 _857 = fa_light_texel(param_10);\n            int param_11 = _734 + 6;\n            vec4 _862 = fa_light_texel(param_11);\n            float _863 = _862.w;\n            int param_12 = _734 + 2;\n            vec3 _870 = normalize(fa_light_texel(param_12).xyz);\n            bool _872 = _863 > 1.5;\n            bool _880;\n            if (!_872)\n            {\n                _880 = dot(_870, to_light) < 0.0;\n            }\n            else\n            {\n                _880 = _872;\n            }\n            front = _880;\n            vec3 r = vec3(0.0);\n            vec3 _889 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _893 = dot(n, n) > 0.5;\n            bool _901;\n            if (_893)\n            {\n                _901 = dot(_889, _889) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _901 = _893;\n            }\n            if (_901)\n            {\n                r = reflect(-normalize(_889), normalize(n));\n            }\n            vec3 param_13 = _823;\n            vec3 param_14 = _870;\n            vec3 param_15 = _852.xyz;\n            vec3 param_16 = _857.xyz;\n            float param_17 = _852.w;\n            float param_18 = _857.w;\n            float param_19 = _863;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _937 = length(to_light);\n        dist = _937;\n        l = to_light / vec3(max(_937, 9.9999997473787516355514526367188e-05));\n        float _951 = reach / max(_742.w, 0.001000000047497451305389404296875);\n        float _957 = clamp(1.0 - (_951 * _951), 0.0, 1.0);\n        float _959;\n        if (front)\n        {\n            _959 = _957 * _957;\n        }\n        else\n        {\n            _959 = 0.0;\n        }\n        atten = _959;\n        bool _970 = _750 < 2.5;\n        if ((_750 > 1.5) && _970)\n        {\n            int param_22 = _734 + 2;\n            vec4 _978 = fa_light_texel(param_22);\n            float _988 = _978.w;\n            int param_23 = _734 + 3;\n            vec4 _993 = fa_light_texel(param_23);\n            float _994 = _993.x;\n            float cos_inner = _994;\n            if (_994 > 1.5)\n            {\n                cos_inner = mix(_988, 1.0, 0.25);\n            }\n            atten *= smoothstep(_988, cos_inner, dot(-l, normalize(_978.xyz)));\n        }\n        if (_738 && (_750 < 1.5))\n        {\n            int param_24 = _734 + 6;\n            vec4 _1018 = fa_light_texel(param_24);\n            if (_1018.z > 0.5)\n            {\n                vec3 _1026 = -to_light;\n                int param_25 = _734 + 4;\n                int param_26 = _734 + 5;\n                vec3 _1040 = fa_light_texel(param_25).xyz;\n                vec3 _1044 = fa_light_texel(param_26).xyz;\n                vec3 _1053 = vec3(dot(_1026, _1040), dot(_1026, _1044), dot(_1026, cross(_1040, _1044)));\n                vec3 param_27 = _1053;\n                int _1057 = fa_cube_face(param_27);\n                int param_28 = _1057;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1084 = vec2(dot(_1053, cross(param_29, param_30)), dot(_1053, param_30)) / vec2(max(dot(_1053, param_29), 9.9999997473787516355514526367188e-05));\n                int _1088 = _1057 / 3;\n                vec2 param_31 = _1018.xy + (vec2(float(_1057 - (_1088 * 3)), float(_1088)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1084.x), 0.5 - (0.5 * _1084.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _734 + 7;\n            vec4 _1118 = fa_light_texel(param_33);\n            if (_1118.z > 0.5)\n            {\n                int param_34 = _734 + 2;\n                int param_35 = _734 + 4;\n                int param_36 = _734 + 5;\n                vec2 param_37 = _1118.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_738 && _970)\n            {\n                int param_42 = _734 + 6;\n                vec4 _1165 = fa_light_texel(param_42);\n                int param_43 = _734 + 7;\n                vec4 _1170 = fa_light_texel(param_43);\n                bool _1173 = _1165.z > 0.5;\n                bool _1180;\n                if (!_1173)\n                {\n                    _1180 = _1170.z > 0.5;\n                }\n                else\n                {\n                    _1180 = _1173;\n                }\n                if (_1180)\n                {\n                    int param_44 = _734 + 2;\n                    vec4 _1187 = fa_light_texel(param_44);\n                    vec3 _1191 = normalize(_1187.xyz);\n                    int param_45 = _734 + 4;\n                    vec4 _1196 = fa_light_texel(param_45);\n                    int param_46 = _734 + 5;\n                    vec4 _1201 = fa_light_texel(param_46);\n                    if (_1173)\n                    {\n                        vec3 _1209 = -to_light;\n                        float _1216 = _1187.w;\n                        float _1232 = 0.5 / max(dot(_1209, _1191) * (sqrt(max(1.0 - (_1216 * _1216), 0.0)) / max(_1216, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1165.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1209, _1196.xyz) * _1232), 0.5 - (dot(_1209, _1201.xyz) * _1232));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1170.z > 0.5)\n                    {\n                        vec2 param_49 = _1170.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1191;\n                        vec3 param_52 = _1196.xyz;\n                        vec3 param_53 = _1201.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4644 = _747.xyz * atten;\n    if (_738)\n    {\n        _4644 *= fa_light_tint;\n    }\n    int _1300;\n    if (_764)\n    {\n        _1300 = 0;\n    }\n    else\n    {\n        _1300 = ((_750 > 1.5) && (_750 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4644, atten, 1.0, dist, _1300);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2037;\n    if (i == 0)\n    {\n        _2037 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2053;\n        if (i == 1)\n        {\n            _2053 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2061;\n            if (i == 2)\n            {\n                _2061 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2061 = fa_shadows[24].w;\n            }\n            _2053 = _2061;\n        }\n        _2037 = _2053;\n    }\n    return _2037;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2094 = fa_shadow_depth(param, param_1);\n    float _2098;\n    if (conv.x < 0.5)\n    {\n        _2098 = _2094;\n    }\n    else\n    {\n        _2098 = (conv.y * conv.z) / (conv.z - (_2094 * (conv.z - conv.y)));\n    }\n    return _2098;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2025 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2025), sin(_2025)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2144 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2153;\n        if (k < 0.0)\n        {\n            _2153 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2153 = k;\n        }\n        float _2173 = clamp((_2153 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2144;\n            vec2 _2192 = fa_shadow_vogel(param_3, param_4, param_5) * _2173;\n            vec2 param_6 = uv + (_2192 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2204 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2204 < (zr - (length(_2192) * plane)))\n            {\n                sum += _2204;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2230 = sum / cnt;\n        float _2240;\n        if (k < 0.0)\n        {\n            _2240 = (-k) / max(_2230, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2240 = k;\n        }\n        radius = clamp(((max(zr - _2230, 0.0) * unit) * _2240) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2262 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2262; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2262;\n        float param_11 = _2144;\n        vec2 _2281 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2281 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2281) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2262);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2323 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2328 = clamp(dot(n, l), 0.0, 1.0);\n    float _2334 = sqrt(1.0 - (_2328 * _2328));\n    float _2341 = min(_2334 / max(_2328, 0.20000000298023223876953125), 4.0);\n    float _2346;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2346 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2346 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2371 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2346 * _2334)), 1.0);\n    float _2378 = _2371.x;\n    bool _2381 = _2378 < fa_shadows[ci * 1 + 16].x;\n    bool _2390;\n    if (!_2381)\n    {\n        _2390 = _2378 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2390 = _2381;\n    }\n    bool _2399;\n    if (!_2390)\n    {\n        _2399 = _2371.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2399 = _2390;\n    }\n    bool _2408;\n    if (!_2399)\n    {\n        _2408 = _2371.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2408 = _2399;\n    }\n    bool _2415;\n    if (!_2408)\n    {\n        _2415 = _2371.z > 1.0;\n    }\n    else\n    {\n        _2415 = _2408;\n    }\n    if (_2415)\n    {\n        return -1.0;\n    }\n    float _2423;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2423 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2423 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2371.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2371.z - ((_2423 * (1.0 + (0.5 * _2341))) / _2323);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2323;\n    float param_5 = _2323 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2341, 3.0)) * 0.5) / _2323;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2801 = int(fa_shadows[25].x + 0.5);\n    if (_2801 < 1)\n    {\n        return 1.0;\n    }\n    float _2816 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2801 - 1;\n    if (_2816 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2828 = _2801 > 1;\n    bool _2835;\n    if (_2828)\n    {\n        _2835 = _2816 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2835 = _2828;\n    }\n    if (_2835)\n    {\n        ci = 1;\n    }\n    bool _2839 = _2801 > 2;\n    bool _2846;\n    if (_2839)\n    {\n        _2846 = _2816 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2846 = _2839;\n    }\n    if (_2846)\n    {\n        ci = 2;\n    }\n    bool _2850 = _2801 > 3;\n    bool _2857;\n    if (_2850)\n    {\n        _2857 = _2816 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2857 = _2850;\n    }\n    if (_2857)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2801)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2883 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2883;\n        if (_2883 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2908;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2908 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2908 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2927 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2908, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2938 = clamp((_2816 - (fa_shadow_split_at(param_7) - _2927)) / _2927, 0.0, 1.0);\n        if (_2938 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2801)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2959 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2959;\n                if (_2959 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2938);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2481 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2488;\n    if (!_2481)\n    {\n        _2488 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2488 = _2481;\n    }\n    if (_2488)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2501 = fa_light_texel(param);\n    float _2502 = _2501.x;\n    if (_2502 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2511 = int(_2502 + 0.5);\n    int param_1 = _2511;\n    vec4 _2515 = fa_light_texel(param_1);\n    int param_2 = _2511 + 1;\n    vec4 _2520 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2523 = _2515.y;\n    if (_2523 > 0.0)\n    {\n        float _2540 = 1.0 - smoothstep(0.75 * _2523, _2523, length(world - fa_shadows[27].xyz));\n        fade = _2540;\n        if (_2540 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2515.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2564 = (_2511 + 2) + (face * 6);\n    int param_4 = _2564;\n    int param_5 = _2564 + 1;\n    int param_6 = _2564 + 3;\n    vec4 _2578 = fa_light_texel(param_6);\n    int param_7 = _2564 + 4;\n    vec4 _2583 = fa_light_texel(param_7);\n    int param_8 = _2564 + 5;\n    vec4 _2588 = fa_light_texel(param_8);\n    float _2600 = _2588.x * max(dot(_2578, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2605 = clamp(dot(n, l), 0.0, 1.0);\n    float _2628 = clamp(dot(n, _2578.xyz), -1.0, 1.0);\n    float _2647 = min(sqrt(1.0 - (_2628 * _2628)) / max(abs(dot(n, world - lpos)) / max(dot(_2578, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2650 = _2520.y;\n    float _2652;\n    if (_2650 > 0.0)\n    {\n        _2652 = _2650;\n    }\n    else\n    {\n        _2652 = 1.5 * _2600;\n    }\n    vec4 _2672 = vec4(world + (n * (_2652 * sqrt(1.0 - (_2605 * _2605)))), 1.0);\n    float _2676 = dot(_2578, _2672);\n    float _2679 = _2588.y;\n    if (_2676 < _2679)\n    {\n        return 1.0;\n    }\n    vec2 _2694 = vec2(dot(fa_light_texel(param_4), _2672), dot(fa_light_texel(param_5), _2672)) / vec2(_2676);\n    float _2696 = _2694.x;\n    bool _2699 = _2696 < _2583.x;\n    bool _2708;\n    if (!_2699)\n    {\n        _2708 = _2696 > _2583.z;\n    }\n    else\n    {\n        _2708 = _2699;\n    }\n    bool _2717;\n    if (!_2708)\n    {\n        _2717 = _2694.y < _2583.y;\n    }\n    else\n    {\n        _2717 = _2708;\n    }\n    bool _2726;\n    if (!_2717)\n    {\n        _2726 = _2694.y > _2583.w;\n    }\n    else\n    {\n        _2726 = _2717;\n    }\n    if (_2726)\n    {\n        return 1.0;\n    }\n    float _2732 = _2520.x;\n    float _2734;\n    if (_2732 > 0.0)\n    {\n        _2734 = _2732;\n    }\n    else\n    {\n        _2734 = 1.5 * _2600;\n    }\n    vec2 param_9 = _2694;\n    vec4 param_10 = _2583;\n    float param_11 = _2676 - (_2734 * (1.0 + (0.5 * _2647)));\n    float param_12 = _2600;\n    float param_13 = 1.0;\n    float param_14 = _2588.z * 0.25;\n    float param_15 = (_2600 * min(_2647, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2679, _2588.z);\n    int param_17 = int(_2515.z + 0.5);\n    float param_18 = _2515.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3240 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3247;\n    if (!_3240)\n    {\n        _3247 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3247 = _3240;\n    }\n    if (_3247)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3260 = fa_light_texel(param);\n    float _3261 = _3260.y;\n    float len = _3261;\n    if (_3261 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3273 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3283 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3273);\n    if (_3283 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3289 = len;\n    float _3292 = min(_3289, 0.89999997615814208984375 * dist);\n    len = _3292;\n    float _3298 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3273);\n    float _3303 = _3298 + (0.5 * _3292);\n    vec3 _3309 = world + (gn * _3298);\n    float _3311 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3376;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3327 = (float(k) + _3311) * 0.083333335816860198974609375;\n        vec3 _3335 = _3309 + (l * (_3327 * len));\n        vec4 _3341 = vec4(_3335, 1.0);\n        float _3347 = dot(fa_mesh_fs_params[28], _3341);\n        if (_3347 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3367 = vec2(dot(fa_mesh_fs_params[26], _3341), dot(fa_mesh_fs_params[27], _3341)) / vec2(_3347);\n        float _3371 = _3367.x * 0.5;\n        float _3372 = _3371 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3376 = (_3367.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3376 = 0.5 - (_3367.y * 0.5);\n        }\n        bool _3392 = _3372 < 0.0;\n        bool _3399;\n        if (!_3392)\n        {\n            _3399 = _3372 >= 1.0;\n        }\n        else\n        {\n            _3399 = _3392;\n        }\n        bool _3406;\n        if (!_3399)\n        {\n            _3406 = _3376 < 0.0;\n        }\n        else\n        {\n            _3406 = _3399;\n        }\n        bool _3413;\n        if (!_3406)\n        {\n            _3413 = _3376 >= 1.0;\n        }\n        else\n        {\n            _3413 = _3406;\n        }\n        if (_3413)\n        {\n            break;\n        }\n        vec4 _3432 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3372, _3376) * fa_mesh_fs_params[24].zw), 0);\n        if (_3432.w < 0.5)\n        {\n            continue;\n        }\n        float _3451 = (dot(fa_mesh_fs_params[29].xyz, _3335) + fa_mesh_fs_params[29].w) - _3432.x;\n        if ((_3451 > _3298) && (_3451 < _3303))\n        {\n            occ = max(occ, (1.0 - (_3327 * _3327)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3372, 0.5 - _3371), min(_3376, 1.0 - _3376))));\n        }\n    }\n    return 1.0 - (occ * _3283);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3554 = fa_baked_keep(param);\n    if (_3554 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3580 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4670 = _3580.color;\n    float _4671 = _3580.attenuation;\n    float _4672 = _3580.shadow;\n    bool _3583 = _3580.type == 0;\n    if (_3583 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3580.direction;\n        float _3594 = fa_shadow_factor(param_5, param_6);\n        _4672 = _3594;\n        _4670 *= _3594;\n    }\n    else\n    {\n        bool _3605 = _3580.type != 0;\n        bool _3611;\n        if (_3605)\n        {\n            _3611 = _4671 > 0.0;\n        }\n        else\n        {\n            _3611 = _3605;\n        }\n        if (_3611)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3580.direction;\n            float _3630 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4672 = _3630;\n            _4670 *= _3630;\n        }\n    }\n    bool _3640 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3646;\n    if (_3640)\n    {\n        _3646 = _4671 > 0.0;\n    }\n    else\n    {\n        _3646 = _3640;\n    }\n    if (_3646)\n    {\n        float _3653;\n        if (_3583)\n        {\n            _3653 = 1000000000.0;\n        }\n        else\n        {\n            _3653 = _3580._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3580.direction;\n        float param_18 = _3653;\n        float _3671 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4672 *= _3671;\n        _4670 *= _3671;\n    }\n    float _3684 = _4671;\n    float _3685 = _3684 * _3554;\n    _4671 = _3685;\n    vec3 _3689 = _4670;\n    vec3 _3690 = _3689 * _3554;\n    _4670 = _3690;\n    return LightSample(_3580.direction, _3690, _3685, _4672, _3580._distance, _3580.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2983 = int(fa_shadows[25].x + 0.5);\n    float _2993 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2998 = _2983 > 0;\n    bool _3007;\n    if (_2998)\n    {\n        int param = _2983 - 1;\n        _3007 = _2993 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3007 = _2998;\n    }\n    if (_3007)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3013 = _2983 > 1;\n        bool _3020;\n        if (_3013)\n        {\n            _3020 = _2993 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3020 = _3013;\n        }\n        if (_3020)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3026 = _2983 > 2;\n        bool _3033;\n        if (_3026)\n        {\n            _3033 = _2993 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3033 = _3026;\n        }\n        if (_3033)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3039 = _2983 > 3;\n        bool _3046;\n        if (_3039)\n        {\n            _3046 = _2993 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3046 = _3039;\n        }\n        if (_3046)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4511 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4511 = -_4511;\n    }\n    vec3 _4102 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4511, fa_world_tangent, fa_uv, fa_vertex_color, _4102, gl_FrontFacing);\n    Surface _4110 = fa_standard_surface(param_1);\n    vec3 _4542 = _4110.albedo;\n    float _4543 = _4110.alpha;\n    vec3 _4544 = _4110.normal;\n    float _4545 = _4110.metallic;\n    float _4546 = _4110.roughness;\n    float _4547 = _4110.occlusion;\n    vec3 _4548 = _4110.emission;\n    float _4549 = _4110.clearcoat;\n    float _4550 = _4110.clearcoat_roughness;\n    vec3 _4551 = _4110.sheen_color;\n    float _4552 = _4110.sheen_roughness;\n    float _4553 = _4110.anisotropy;\n    float _4554 = _4110.anisotropy_rotation;\n    float _4555 = _4110.specular;\n    float _4556 = _4110.ior;\n    vec3 _4557 = _4110.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4511, fa_world_tangent, fa_uv, fa_vertex_color, _4102, gl_FrontFacing);\n    Surface param_3 = _4110;\n    surface(param_2, param_3);\n    _4542 = param_3.albedo;\n    _4543 = param_3.alpha;\n    _4544 = param_3.normal;\n    _4545 = param_3.metallic;\n    _4546 = param_3.roughness;\n    _4547 = param_3.occlusion;\n    _4548 = param_3.emission;\n    _4549 = param_3.clearcoat;\n    _4550 = param_3.clearcoat_roughness;\n    _4551 = param_3.sheen_color;\n    _4552 = param_3.sheen_roughness;\n    _4553 = param_3.anisotropy;\n    _4554 = param_3.anisotropy_rotation;\n    _4555 = param_3.specular;\n    _4556 = param_3.ior;\n    _4557 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4511;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4542 = param_6;\n    _4544 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4542;\n    }\n    else\n    {\n        vec3 _4148 = _4544;\n        vec3 _4149 = normalize(_4148);\n        _4544 = _4149;\n        vec3 param_8 = _4149;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4542) * _4547;\n        int _4168 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4168; ln++)\n        {\n            int param_9 = ln;\n            int _4181 = fa_cl_light(param_9);\n            int param_10 = _4181;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _4181;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _4511;\n            LightSample _4197 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _4511, fa_world_tangent, fa_uv, fa_vertex_color, _4102, gl_FrontFacing);\n            Surface param_15 = Surface(_4542, _4543, _4544, _4545, _4546, _4547, _4548, _4549, _4550, _4551, _4552, _4553, _4554, _4555, _4556, _4557);\n            LightSample param_16 = _4197;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _4212 = result;\n    vec3 _4213 = _4212 + _4548;\n    result = _4213;\n    vec3 param_17 = _4213;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _4222 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4229;\n    if (!_4222)\n    {\n        _4229 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4229 = _4222;\n    }\n    if (_4229)\n    {\n        vec3 _4238 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4244 = dot(_4238, fa_mesh_fs_params[9].xyz);\n        bool _4248 = fa_mesh_fs_params[9].w > 0.5;\n        float _4249;\n        if (_4248)\n        {\n            _4249 = _4244;\n        }\n        else\n        {\n            _4249 = length(_4238);\n        }\n        float _4261 = _4249 - fa_mesh_fs_params[8].x;\n        if (_4261 > 0.0)\n        {\n            float _4270 = fa_mesh_fs_params[7].w * _4261;\n            float tau = _4270 * _4270;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4286;\n                if (_4248)\n                {\n                    _4286 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4244);\n                }\n                else\n                {\n                    _4286 = fa_mesh_fs_params[0].y;\n                }\n                float _4307 = mix(_4286, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4249, 0.0, 1.0));\n                float _4311 = fa_world_pos.y - _4307;\n                float _4316 = _4307 - fa_mesh_fs_params[8].z;\n                float _4321 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4324 = _4316 <= 0.0;\n                bool _4325 = !_4324;\n                bool _4331;\n                if (_4325)\n                {\n                    _4331 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4331 = _4324;\n                }\n                float _4332;\n                if (_4331)\n                {\n                    _4332 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4332 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4316, 80.0));\n                }\n                bool _4359;\n                if (_4325)\n                {\n                    _4359 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4359 = _4324;\n                }\n                float _4360;\n                if (_4359)\n                {\n                    _4360 = fa_mesh_fs_params[8].y * _4316;\n                }\n                else\n                {\n                    _4360 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4316, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4385 = _4321 <= 0.0;\n                bool _4392;\n                if (!_4385)\n                {\n                    _4392 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4392 = _4385;\n                }\n                float _4393;\n                if (_4392)\n                {\n                    _4393 = fa_mesh_fs_params[8].y * _4321;\n                }\n                else\n                {\n                    _4393 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4321, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4420;\n                if (abs(_4311) < 0.001000000047497451305389404296875)\n                {\n                    _4420 = _4332;\n                }\n                else\n                {\n                    _4420 = (_4393 - _4360) / _4311;\n                }\n                tau += (_4261 * max(_4420, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4543);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_390",
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
            "inst_name": "_2047",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _388 = _273.world_pos;\n    fa_world_pos = _388;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_388, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nuniform vec4 fa_shadows[30];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_lightmap_fa_env_smp;\nlayout(binding = 8) uniform samplerCube fa_env_tex_fa_env_smp;\nlayout(binding = 9) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 10) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 11) uniform sampler2D fa_screen_tex_fa_shadow_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1318 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1325;\n    if (!_1318)\n    {\n        _1325 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1325 = _1318;\n    }\n    bool _1333;\n    if (!_1325)\n    {\n        _1333 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1333 = _1325;\n    }\n    bool _1340;\n    if (!_1333)\n    {\n        _1340 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1340 = _1333;\n    }\n    bool _1347;\n    if (!_1340)\n    {\n        _1347 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1347 = _1340;\n    }\n    if (_1347)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1357 = vec4(world_pos, 1.0);\n    float _1363 = dot(fa_mesh_fs_params[16], _1357);\n    if (!(_1363 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1385 = vec2(dot(fa_mesh_fs_params[14], _1357), dot(fa_mesh_fs_params[15], _1357)) / vec2(_1363);\n    int _1389 = int(fa_mesh_fs_params[18].x);\n    int _1393 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1393) + clamp(int(floor(((_1385.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1393 - 1)) * _1389)) + clamp(int(floor(((_1385.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1389 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1469 = fa_cluster_texel(param);\n    return ivec2(int(_1469.x), int(_1469.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _3528 = fa_cluster_lookup(param);\n    fa_cl_slot = _3528.x;\n    fa_cl_local = _3528.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _3733 = fa_linear_to_srgb(param);\n        c = _3733;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _3741 = fa_srgb_to_linear(param_1);\n            c = _3741;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _272;\n    if (i.front_facing)\n    {\n        _272 = i.world_normal;\n    }\n    else\n    {\n        _272 = -i.world_normal;\n    }\n    vec3 _296 = normalize(i.world_tangent.xyz - (_272 * dot(_272, i.world_tangent.xyz)));\n    vec3 _323 = normalize(((_296 * m.x) + ((cross(_272, _296) * i.world_tangent.w) * m.y)) + (_272 * m.z));\n    vec3 _326;\n    if (i.front_facing)\n    {\n        _326 = _323;\n    }\n    else\n    {\n        _326 = -_323;\n    }\n    return _326;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _3772 = fa_tex_fix(param_2, param_3);\n    vec4 _4838 = base_t;\n    _4838.x = _3772.x;\n    _4838.y = _3772.y;\n    _4838.z = _3772.z;\n    base_t = _4838;\n    vec4 _3786 = (_4838 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _4690 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _3818 = fa_tex_fix(param_6, param_7);\n        vec3 _3821 = (_3818 * 2.0) - vec3(1.0);\n        vec2 _3826 = _3821.xy * fa_mesh_fs_params[6].x;\n        vec3 _4846 = _3821;\n        _4846.x = _3826.x;\n        _4846.y = _3826.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _4846;\n        _4690 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _3854 = fa_tex_fix(param_12, param_13);\n    vec4 _4849 = mrt;\n    _4849.x = _3854.x;\n    _4849.y = _3854.y;\n    _4849.z = _3854.z;\n    mrt = _4849;\n    vec4 _3882 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _3882.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _3893 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _3923 = fa_tex_fix(param_20, param_21);\n    float _4695 = fa_mesh_fs_params[20].x;\n    float _4696 = fa_mesh_fs_params[20].y;\n    float _4699 = fa_mesh_fs_params[20].z;\n    float _4698 = fa_mesh_fs_params[21].w;\n    float _4701 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _4695 *= _3893.y;\n            _4696 *= _3893.z;\n            _4698 *= _3882.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _4699 *= mrt.x;\n            _4701 *= mrt.w;\n        }\n    }\n    return Surface(_3786.xyz, _3786.w, _4690, clamp(fa_mesh_fs_params[5].x * _3854.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _3854.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_3893.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _3923), _4695, _4696, fa_mesh_fs_params[21].xyz, _4698, _4699, fa_mesh_fs_params[20].w, _4701, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1549 = rect.zw - rect.xy;\n    vec2 _1553 = _1549 * atlas;\n    vec2 _1557 = ddx * _1553;\n    vec2 _1561 = ddy * _1553;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1549), clamp(0.5 * log2(max(max(dot(_1557, _1557), dot(_1561, _1561)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1594 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1601;\n    if (!_1594)\n    {\n        _1601 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1601 = _1594;\n    }\n    if (_1601)\n    {\n        return;\n    }\n    vec3 _1607 = dFdx(world_pos);\n    vec3 _1610 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1614 = fa_cluster_texel(param);\n    int _1618 = int(_1614.w);\n    if (_1618 < 1)\n    {\n        return;\n    }\n    int _1628 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1628;\n    vec4 _1632 = fa_light_texel(param_1);\n    vec2 _1635 = _1632.yz;\n    int _1639 = int(_1632.w);\n    int param_2 = _1628 + 1;\n    vec4 _1644 = fa_light_texel(param_2);\n    float _1645 = _1644.x;\n    int _1651 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1655 = int(_1614.z);\n    vec3 _1920;\n    for (int k = 0; k < _1618; k++)\n    {\n        int _1668 = _1655 + k;\n        int param_3 = _1639 + (_1668 >> 2);\n        int _1685 = (_1628 + 2) + (int(fa_light_texel(param_3)[_1668 & 3]) * 7);\n        int param_4 = _1685 + 6;\n        vec4 _1690 = fa_light_texel(param_4);\n        if (((int(_1690.w + 0.5) >> _1651) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1685;\n        vec4 _1705 = fa_light_texel(param_5);\n        int param_6 = _1685 + 1;\n        vec4 _1710 = fa_light_texel(param_6);\n        int param_7 = _1685 + 2;\n        vec4 _1715 = fa_light_texel(param_7);\n        vec3 _1718 = _1705.xyz;\n        float _1723 = dot(_1718, world_pos) + _1705.w;\n        vec3 _1725 = _1710.xyz;\n        float _1730 = dot(_1725, world_pos) + _1710.w;\n        vec3 _1732 = _1715.xyz;\n        float _1737 = dot(_1732, world_pos) + _1715.w;\n        bool _1742 = abs(_1723) > 0.5;\n        bool _1750;\n        if (!_1742)\n        {\n            _1750 = abs(_1730) > 0.5;\n        }\n        else\n        {\n            _1750 = _1742;\n        }\n        bool _1758;\n        if (!_1750)\n        {\n            _1758 = abs(_1737) > 0.5;\n        }\n        else\n        {\n            _1758 = _1750;\n        }\n        if (_1758)\n        {\n            continue;\n        }\n        float _1773 = clamp(dot(geo_normal, normalize(_1732)) * _1690.z, 0.0, 1.0);\n        if (_1773 <= 0.0)\n        {\n            continue;\n        }\n        float _1793 = (clamp((0.5 - abs(_1737)) * 10.0, 0.0, 1.0) * _1773) * _1690.x;\n        vec2 _1801 = vec2(_1723 + 0.5, 0.5 - _1730);\n        vec2 _1811 = vec2(dot(_1718, _1607), dot(_1725, _1607));\n        vec2 _1821 = vec2(dot(_1718, _1610), dot(_1725, _1610));\n        int param_8 = _1685 + 5;\n        vec4 _1826 = fa_light_texel(param_8);\n        int param_9 = _1685 + 3;\n        vec4 _1831 = fa_light_texel(param_9);\n        int param_10 = _1685 + 4;\n        vec4 _1836 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1826.xyz;\n        bool _1846 = _1831.z > _1831.x;\n        if (_1846)\n        {\n            vec4 param_11 = _1831;\n            vec2 param_12 = _1801;\n            vec2 param_13 = _1635;\n            vec2 param_14 = _1811;\n            vec2 param_15 = _1821;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1645 > 0.5) && (_1645 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1872 = fa_dc_to_linear(param_16);\n                vec4 _4770 = tx;\n                _4770.x = _1872.x;\n                _4770.y = _1872.y;\n                _4770.z = _1872.z;\n                tx = _4770;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1793 * tex_a) * _1826.w, 0.0, 1.0)));\n        if (_1836.z > _1836.x)\n        {\n            vec4 param_17 = _1836;\n            vec2 param_18 = _1801;\n            vec2 param_19 = _1635;\n            vec2 param_20 = _1811;\n            vec2 param_21 = _1821;\n            vec4 _1916 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1645 > 1.5)\n            {\n                vec3 param_22 = _1916.xyz;\n                vec3 _1926 = fa_dc_to_srgb(param_22);\n                _1920 = _1926;\n            }\n            else\n            {\n                _1920 = _1916.xyz;\n            }\n            vec3 _1935 = (_1920 * 2.0) - vec3(1.0);\n            vec2 _1940 = _1935.xy * _1690.y;\n            vec3 _1962 = (normalize(_1718) * _1940.x) + (normalize(_1725) * _1940.y);\n            vec3 _1965 = normalize(normal);\n            normal = normalize(mix(_1965, normalize((_1965 * max(_1935.z, 0.0500000007450580596923828125)) + (_1962 - (_1965 * dot(_1965, _1962)))), vec3(clamp(_1793 * (_1846 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nvec3 fa_sky_sh_coef(int k)\n{\n    vec3 v = textureLod(fa_env_tex_fa_env_smp, vec3(1.0, 1.0 - (float((2 * (k >> 2)) + 1) * 0.25), 1.0 - (float((2 * (k & 3)) + 1) * 0.25)), 5.0).xyz;\n    if (fa_mesh_fs_params[11].w > 1.5)\n    {\n        v = (v - vec3(0.5)) * 8.0;\n    }\n    return v;\n}\n\nvec3 fa_sh_eval(vec3 c[9], vec3 n)\n{\n    vec3 _3160 = max((((c[0] * 0.2820948064327239990234375) + (((c[1] * (0.3257350027561187744140625 * n.y)) + (c[2] * (0.3257350027561187744140625 * n.z))) + (c[3] * (0.3257350027561187744140625 * n.x)))) + (((c[4] * ((0.2731371223926544189453125 * n.x) * n.y)) + (c[5] * ((0.2731371223926544189453125 * n.y) * n.z))) + (c[6] * (0.078847892582416534423828125 * (((3.0 * n.z) * n.z) - 1.0))))) + ((c[7] * ((0.2731371223926544189453125 * n.x) * n.z)) + (c[8] * (0.13656856119632720947265625 * ((n.x * n.x) - (n.y * n.y))))), vec3(0.0));\n    return _3160;\n}\n\nvec3 fa_ambient_light(vec3 n)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            int param = k;\n            c[k] = fa_sky_sh_coef(param);\n        }\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return fa_sh_eval(param_1, param_2);\n    }\n    return fa_mesh_fs_params[1].xyz;\n}\n\nvec3 fa_indirect_diffuse(vec3 n)\n{\n    if (fa_lm.z > 0.5)\n    {\n        return textureLod(fa_lightmap_fa_env_smp, fa_lm.xy, 0.0).xyz;\n    }\n    if (fa_mesh_fs_params[30].w > 0.0)\n    {\n        vec3 c[9];\n        for (int k = 0; k < 9; k++)\n        {\n            c[k] = fa_mesh_fs_params[k * 1 + 30].xyz;\n        }\n        vec3 param = n;\n        vec3 param_1[9] = c;\n        vec3 param_2 = n;\n        return mix(fa_ambient_light(param), fa_sh_eval(param_1, param_2), vec3(clamp(fa_mesh_fs_params[30].w, 0.0, 1.0)));\n    }\n    vec3 param_3 = n;\n    return fa_ambient_light(param_3);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _3498;\n    if (fa_lm.z > 0.5)\n    {\n        _3498 = 0.0;\n    }\n    else\n    {\n        _3498 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _3509 = _3498 < 1.0;\n    bool _3515;\n    if (_3509)\n    {\n        int param = li;\n        _3515 = fa_light_baked(param);\n    }\n    else\n    {\n        _3515 = _3509;\n    }\n    return _3515 ? _3498 : 1.0;\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _568 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _581 = (c - (ru * hx)) - p;\n        vec3 _587 = ru * (2.0 * hx);\n        float _593 = max(dot(_587, _587), 9.9999999392252902907785028219223e-09);\n        float _597 = dot(_581, _587);\n        float t = clamp((-_597) / _593, 0.0, 1.0);\n        if (_568)\n        {\n            float _612 = dot(r, _587);\n            float _618 = _593 - (_612 * _612);\n            if (abs(_618) > (9.9999997473787516355514526367188e-06 * _593))\n            {\n                t = clamp(((dot(r, _581) * _612) - _597) / _618, 0.0, 1.0);\n            }\n        }\n        return (p + _581) + (_587 * t);\n    }\n    vec3 q = p;\n    float _650 = dot(r, axis);\n    bool _658;\n    if (_568)\n    {\n        _658 = abs(_650) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _658 = _568;\n    }\n    if (_658)\n    {\n        float _668 = dot(c - p, axis) / _650;\n        if (_668 > 0.0)\n        {\n            q = p + (r * _668);\n        }\n    }\n    vec3 _681 = q - c;\n    vec2 xy = vec2(dot(_681, ru), dot(_681, uu));\n    if (shape > 0.5)\n    {\n        float _696 = length(xy);\n        if (_696 > hx)\n        {\n            xy *= (hx / _696);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _338 = abs(d);\n    float _340 = _338.x;\n    float _342 = _338.y;\n    bool _343 = _340 >= _342;\n    bool _351;\n    if (_343)\n    {\n        _351 = _340 >= _338.z;\n    }\n    else\n    {\n        _351 = _343;\n    }\n    int _352;\n    if (_351)\n    {\n        _352 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _367;\n        if (_342 >= _338.z)\n        {\n            _367 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _367 = (d.z > 0.0) ? 4 : 5;\n        }\n        _352 = _367;\n    }\n    return _352;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _488 = dot(d, right);\n    float _492 = dot(d, up);\n    float _503;\n    if (((_488 * _488) + (_492 * _492)) > 1.0000000133514319600180897396058e-10)\n    {\n        _503 = atan(_492, _488) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _503 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_503 - floor(_503)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _734 = fa_light_base(param);\n    bool _738 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _734;\n    vec4 _742 = fa_light_texel(param_1);\n    int param_2 = _734 + 1;\n    vec4 _747 = fa_light_texel(param_2);\n    float _750 = _747.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _762 = _738 && (_750 > 2.5);\n    fa_light_is_area = _762;\n    bool _764 = _750 < 0.5;\n    vec3 l;\n    if (_764)\n    {\n        l = normalize(_742.xyz);\n        if (_738)\n        {\n            int param_3 = _734 + 6;\n            vec4 _778 = fa_light_texel(param_3);\n            if (_778.z > 0.5)\n            {\n                int param_4 = _734 + 4;\n                vec4 _788 = fa_light_texel(param_4);\n                int param_5 = _734 + 5;\n                vec4 _793 = fa_light_texel(param_5);\n                vec2 param_6 = _778.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _788.xyz) * _788.w, (-dot(world_pos, _793.xyz)) * _793.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _823 = _742.xyz;\n        vec3 _825 = _823 - world_pos;\n        vec3 to_light = _825;\n        float _828 = length(_825);\n        float reach = _828;\n        bool front = true;\n        if (_762)\n        {\n            int param_8 = _734 + 7;\n            reach = max(_828 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _734 + 4;\n            vec4 _852 = fa_light_texel(param_9);\n            int param_10 = _734 + 5;\n            vec4 _857 = fa_light_texel(param_10);\n            int param_11 = _734 + 6;\n            vec4 _862 = fa_light_texel(param_11);\n            float _863 = _862.w;\n            int param_12 = _734 + 2;\n            vec3 _870 = normalize(fa_light_texel(param_12).xyz);\n            bool _872 = _863 > 1.5;\n            bool _880;\n            if (!_872)\n            {\n                _880 = dot(_870, to_light) < 0.0;\n            }\n            else\n            {\n                _880 = _872;\n            }\n            front = _880;\n            vec3 r = vec3(0.0);\n            vec3 _889 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _893 = dot(n, n) > 0.5;\n            bool _901;\n            if (_893)\n            {\n                _901 = dot(_889, _889) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _901 = _893;\n            }\n            if (_901)\n            {\n                r = reflect(-normalize(_889), normalize(n));\n            }\n            vec3 param_13 = _823;\n            vec3 param_14 = _870;\n            vec3 param_15 = _852.xyz;\n            vec3 param_16 = _857.xyz;\n            float param_17 = _852.w;\n            float param_18 = _857.w;\n            float param_19 = _863;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _937 = length(to_light);\n        dist = _937;\n        l = to_light / vec3(max(_937, 9.9999997473787516355514526367188e-05));\n        float _951 = reach / max(_742.w, 0.001000000047497451305389404296875);\n        float _957 = clamp(1.0 - (_951 * _951), 0.0, 1.0);\n        float _959;\n        if (front)\n        {\n            _959 = _957 * _957;\n        }\n        else\n        {\n            _959 = 0.0;\n        }\n        atten = _959;\n        bool _970 = _750 < 2.5;\n        if ((_750 > 1.5) && _970)\n        {\n            int param_22 = _734 + 2;\n            vec4 _978 = fa_light_texel(param_22);\n            float _988 = _978.w;\n            int param_23 = _734 + 3;\n            vec4 _993 = fa_light_texel(param_23);\n            float _994 = _993.x;\n            float cos_inner = _994;\n            if (_994 > 1.5)\n            {\n                cos_inner = mix(_988, 1.0, 0.25);\n            }\n            atten *= smoothstep(_988, cos_inner, dot(-l, normalize(_978.xyz)));\n        }\n        if (_738 && (_750 < 1.5))\n        {\n            int param_24 = _734 + 6;\n            vec4 _1018 = fa_light_texel(param_24);\n            if (_1018.z > 0.5)\n            {\n                vec3 _1026 = -to_light;\n                int param_25 = _734 + 4;\n                int param_26 = _734 + 5;\n                vec3 _1040 = fa_light_texel(param_25).xyz;\n                vec3 _1044 = fa_light_texel(param_26).xyz;\n                vec3 _1053 = vec3(dot(_1026, _1040), dot(_1026, _1044), dot(_1026, cross(_1040, _1044)));\n                vec3 param_27 = _1053;\n                int _1057 = fa_cube_face(param_27);\n                int param_28 = _1057;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1084 = vec2(dot(_1053, cross(param_29, param_30)), dot(_1053, param_30)) / vec2(max(dot(_1053, param_29), 9.9999997473787516355514526367188e-05));\n                int _1088 = _1057 / 3;\n                vec2 param_31 = _1018.xy + (vec2(float(_1057 - (_1088 * 3)), float(_1088)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1084.x), 0.5 - (0.5 * _1084.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _734 + 7;\n            vec4 _1118 = fa_light_texel(param_33);\n            if (_1118.z > 0.5)\n            {\n                int param_34 = _734 + 2;\n                int param_35 = _734 + 4;\n                int param_36 = _734 + 5;\n                vec2 param_37 = _1118.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_738 && _970)\n            {\n                int param_42 = _734 + 6;\n                vec4 _1165 = fa_light_texel(param_42);\n                int param_43 = _734 + 7;\n                vec4 _1170 = fa_light_texel(param_43);\n                bool _1173 = _1165.z > 0.5;\n                bool _1180;\n                if (!_1173)\n                {\n                    _1180 = _1170.z > 0.5;\n                }\n                else\n                {\n                    _1180 = _1173;\n                }\n                if (_1180)\n                {\n                    int param_44 = _734 + 2;\n                    vec4 _1187 = fa_light_texel(param_44);\n                    vec3 _1191 = normalize(_1187.xyz);\n                    int param_45 = _734 + 4;\n                    vec4 _1196 = fa_light_texel(param_45);\n                    int param_46 = _734 + 5;\n                    vec4 _1201 = fa_light_texel(param_46);\n                    if (_1173)\n                    {\n                        vec3 _1209 = -to_light;\n                        float _1216 = _1187.w;\n                        float _1232 = 0.5 / max(dot(_1209, _1191) * (sqrt(max(1.0 - (_1216 * _1216), 0.0)) / max(_1216, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1165.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1209, _1196.xyz) * _1232), 0.5 - (dot(_1209, _1201.xyz) * _1232));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1170.z > 0.5)\n                    {\n                        vec2 param_49 = _1170.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1191;\n                        vec3 param_52 = _1196.xyz;\n                        vec3 param_53 = _1201.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _4644 = _747.xyz * atten;\n    if (_738)\n    {\n        _4644 *= fa_light_tint;\n    }\n    int _1300;\n    if (_764)\n    {\n        _1300 = 0;\n    }\n    else\n    {\n        _1300 = ((_750 > 1.5) && (_750 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _4644, atten, 1.0, dist, _1300);\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2037;\n    if (i == 0)\n    {\n        _2037 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2053;\n        if (i == 1)\n        {\n            _2053 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2061;\n            if (i == 2)\n            {\n                _2061 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2061 = fa_shadows[24].w;\n            }\n            _2053 = _2061;\n        }\n        _2037 = _2053;\n    }\n    return _2037;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2094 = fa_shadow_depth(param, param_1);\n    float _2098;\n    if (conv.x < 0.5)\n    {\n        _2098 = _2094;\n    }\n    else\n    {\n        _2098 = (conv.y * conv.z) / (conv.z - (_2094 * (conv.z - conv.y)));\n    }\n    return _2098;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2025 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2025), sin(_2025)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2144 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2153;\n        if (k < 0.0)\n        {\n            _2153 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2153 = k;\n        }\n        float _2173 = clamp((_2153 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2144;\n            vec2 _2192 = fa_shadow_vogel(param_3, param_4, param_5) * _2173;\n            vec2 param_6 = uv + (_2192 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2204 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2204 < (zr - (length(_2192) * plane)))\n            {\n                sum += _2204;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2230 = sum / cnt;\n        float _2240;\n        if (k < 0.0)\n        {\n            _2240 = (-k) / max(_2230, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2240 = k;\n        }\n        radius = clamp(((max(zr - _2230, 0.0) * unit) * _2240) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2262 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2262; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2262;\n        float param_11 = _2144;\n        vec2 _2281 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2281 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2281) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2262);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2323 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2328 = clamp(dot(n, l), 0.0, 1.0);\n    float _2334 = sqrt(1.0 - (_2328 * _2328));\n    float _2341 = min(_2334 / max(_2328, 0.20000000298023223876953125), 4.0);\n    float _2346;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2346 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2346 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2371 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2346 * _2334)), 1.0);\n    float _2378 = _2371.x;\n    bool _2381 = _2378 < fa_shadows[ci * 1 + 16].x;\n    bool _2390;\n    if (!_2381)\n    {\n        _2390 = _2378 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2390 = _2381;\n    }\n    bool _2399;\n    if (!_2390)\n    {\n        _2399 = _2371.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2399 = _2390;\n    }\n    bool _2408;\n    if (!_2399)\n    {\n        _2408 = _2371.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2408 = _2399;\n    }\n    bool _2415;\n    if (!_2408)\n    {\n        _2415 = _2371.z > 1.0;\n    }\n    else\n    {\n        _2415 = _2408;\n    }\n    if (_2415)\n    {\n        return -1.0;\n    }\n    float _2423;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2423 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2423 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2371.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2371.z - ((_2423 * (1.0 + (0.5 * _2341))) / _2323);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2323;\n    float param_5 = _2323 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2341, 3.0)) * 0.5) / _2323;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2801 = int(fa_shadows[25].x + 0.5);\n    if (_2801 < 1)\n    {\n        return 1.0;\n    }\n    float _2816 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2801 - 1;\n    if (_2816 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2828 = _2801 > 1;\n    bool _2835;\n    if (_2828)\n    {\n        _2835 = _2816 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2835 = _2828;\n    }\n    if (_2835)\n    {\n        ci = 1;\n    }\n    bool _2839 = _2801 > 2;\n    bool _2846;\n    if (_2839)\n    {\n        _2846 = _2816 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2846 = _2839;\n    }\n    if (_2846)\n    {\n        ci = 2;\n    }\n    bool _2850 = _2801 > 3;\n    bool _2857;\n    if (_2850)\n    {\n        _2857 = _2816 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2857 = _2850;\n    }\n    if (_2857)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2801)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2883 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2883;\n        if (_2883 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2908;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2908 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2908 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2927 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2908, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2938 = clamp((_2816 - (fa_shadow_split_at(param_7) - _2927)) / _2927, 0.0, 1.0);\n        if (_2938 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2801)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _2959 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _2959;\n                if (_2959 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2938);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2481 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2488;\n    if (!_2481)\n    {\n        _2488 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2488 = _2481;\n    }\n    if (_2488)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2501 = fa_light_texel(param);\n    float _2502 = _2501.x;\n    if (_2502 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2511 = int(_2502 + 0.5);\n    int param_1 = _2511;\n    vec4 _2515 = fa_light_texel(param_1);\n    int param_2 = _2511 + 1;\n    vec4 _2520 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2523 = _2515.y;\n    if (_2523 > 0.0)\n    {\n        float _2540 = 1.0 - smoothstep(0.75 * _2523, _2523, length(world - fa_shadows[27].xyz));\n        fade = _2540;\n        if (_2540 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2515.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2564 = (_2511 + 2) + (face * 6);\n    int param_4 = _2564;\n    int param_5 = _2564 + 1;\n    int param_6 = _2564 + 3;\n    vec4 _2578 = fa_light_texel(param_6);\n    int param_7 = _2564 + 4;\n    vec4 _2583 = fa_light_texel(param_7);\n    int param_8 = _2564 + 5;\n    vec4 _2588 = fa_light_texel(param_8);\n    float _2600 = _2588.x * max(dot(_2578, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2605 = clamp(dot(n, l), 0.0, 1.0);\n    float _2628 = clamp(dot(n, _2578.xyz), -1.0, 1.0);\n    float _2647 = min(sqrt(1.0 - (_2628 * _2628)) / max(abs(dot(n, world - lpos)) / max(dot(_2578, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2650 = _2520.y;\n    float _2652;\n    if (_2650 > 0.0)\n    {\n        _2652 = _2650;\n    }\n    else\n    {\n        _2652 = 1.5 * _2600;\n    }\n    vec4 _2672 = vec4(world + (n * (_2652 * sqrt(1.0 - (_2605 * _2605)))), 1.0);\n    float _2676 = dot(_2578, _2672);\n    float _2679 = _2588.y;\n    if (_2676 < _2679)\n    {\n        return 1.0;\n    }\n    vec2 _2694 = vec2(dot(fa_light_texel(param_4), _2672), dot(fa_light_texel(param_5), _2672)) / vec2(_2676);\n    float _2696 = _2694.x;\n    bool _2699 = _2696 < _2583.x;\n    bool _2708;\n    if (!_2699)\n    {\n        _2708 = _2696 > _2583.z;\n    }\n    else\n    {\n        _2708 = _2699;\n    }\n    bool _2717;\n    if (!_2708)\n    {\n        _2717 = _2694.y < _2583.y;\n    }\n    else\n    {\n        _2717 = _2708;\n    }\n    bool _2726;\n    if (!_2717)\n    {\n        _2726 = _2694.y > _2583.w;\n    }\n    else\n    {\n        _2726 = _2717;\n    }\n    if (_2726)\n    {\n        return 1.0;\n    }\n    float _2732 = _2520.x;\n    float _2734;\n    if (_2732 > 0.0)\n    {\n        _2734 = _2732;\n    }\n    else\n    {\n        _2734 = 1.5 * _2600;\n    }\n    vec2 param_9 = _2694;\n    vec4 param_10 = _2583;\n    float param_11 = _2676 - (_2734 * (1.0 + (0.5 * _2647)));\n    float param_12 = _2600;\n    float param_13 = 1.0;\n    float param_14 = _2588.z * 0.25;\n    float param_15 = (_2600 * min(_2647, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2679, _2588.z);\n    int param_17 = int(_2515.z + 0.5);\n    float param_18 = _2515.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3240 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3247;\n    if (!_3240)\n    {\n        _3247 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3247 = _3240;\n    }\n    if (_3247)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3260 = fa_light_texel(param);\n    float _3261 = _3260.y;\n    float len = _3261;\n    if (_3261 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3273 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3283 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3273);\n    if (_3283 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3289 = len;\n    float _3292 = min(_3289, 0.89999997615814208984375 * dist);\n    len = _3292;\n    float _3298 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3273);\n    float _3303 = _3298 + (0.5 * _3292);\n    vec3 _3309 = world + (gn * _3298);\n    float _3311 = fa_shadow_noise();\n    float occ = 0.0;\n    float _3376;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3327 = (float(k) + _3311) * 0.083333335816860198974609375;\n        vec3 _3335 = _3309 + (l * (_3327 * len));\n        vec4 _3341 = vec4(_3335, 1.0);\n        float _3347 = dot(fa_mesh_fs_params[28], _3341);\n        if (_3347 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _3367 = vec2(dot(fa_mesh_fs_params[26], _3341), dot(fa_mesh_fs_params[27], _3341)) / vec2(_3347);\n        float _3371 = _3367.x * 0.5;\n        float _3372 = _3371 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _3376 = (_3367.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _3376 = 0.5 - (_3367.y * 0.5);\n        }\n        bool _3392 = _3372 < 0.0;\n        bool _3399;\n        if (!_3392)\n        {\n            _3399 = _3372 >= 1.0;\n        }\n        else\n        {\n            _3399 = _3392;\n        }\n        bool _3406;\n        if (!_3399)\n        {\n            _3406 = _3376 < 0.0;\n        }\n        else\n        {\n            _3406 = _3399;\n        }\n        bool _3413;\n        if (!_3406)\n        {\n            _3413 = _3376 >= 1.0;\n        }\n        else\n        {\n            _3413 = _3406;\n        }\n        if (_3413)\n        {\n            break;\n        }\n        vec4 _3432 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_3372, _3376) * fa_mesh_fs_params[24].zw), 0);\n        if (_3432.w < 0.5)\n        {\n            continue;\n        }\n        float _3451 = (dot(fa_mesh_fs_params[29].xyz, _3335) + fa_mesh_fs_params[29].w) - _3432.x;\n        if ((_3451 > _3298) && (_3451 < _3303))\n        {\n            occ = max(occ, (1.0 - (_3327 * _3327)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_3372, 0.5 - _3371), min(_3376, 1.0 - _3376))));\n        }\n    }\n    return 1.0 - (occ * _3283);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _3554 = fa_baked_keep(param);\n    if (_3554 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _3580 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _4670 = _3580.color;\n    float _4671 = _3580.attenuation;\n    float _4672 = _3580.shadow;\n    bool _3583 = _3580.type == 0;\n    if (_3583 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _3580.direction;\n        float _3594 = fa_shadow_factor(param_5, param_6);\n        _4672 = _3594;\n        _4670 *= _3594;\n    }\n    else\n    {\n        bool _3605 = _3580.type != 0;\n        bool _3611;\n        if (_3605)\n        {\n            _3611 = _4671 > 0.0;\n        }\n        else\n        {\n            _3611 = _3605;\n        }\n        if (_3611)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _3580.direction;\n            float _3630 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _4672 = _3630;\n            _4670 *= _3630;\n        }\n    }\n    bool _3640 = fa_mesh_fs_params[24].x > 0.5;\n    bool _3646;\n    if (_3640)\n    {\n        _3646 = _4671 > 0.0;\n    }\n    else\n    {\n        _3646 = _3640;\n    }\n    if (_3646)\n    {\n        float _3653;\n        if (_3583)\n        {\n            _3653 = 1000000000.0;\n        }\n        else\n        {\n            _3653 = _3580._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _3580.direction;\n        float param_18 = _3653;\n        float _3671 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _4672 *= _3671;\n        _4670 *= _3671;\n    }\n    float _3684 = _4671;\n    float _3685 = _3684 * _3554;\n    _4671 = _3685;\n    vec3 _3689 = _4670;\n    vec3 _3690 = _3689 * _3554;\n    _4670 = _3690;\n    return LightSample(_3580.direction, _3690, _3685, _4672, _3580._distance, _3580.type);\n}\n\nvec3 light(SurfaceInput i, Surface s, LightSample l)\n{\n    return vec3(0.0);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _2983 = int(fa_shadows[25].x + 0.5);\n    float _2993 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _2998 = _2983 > 0;\n    bool _3007;\n    if (_2998)\n    {\n        int param = _2983 - 1;\n        _3007 = _2993 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3007 = _2998;\n    }\n    if (_3007)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3013 = _2983 > 1;\n        bool _3020;\n        if (_3013)\n        {\n            _3020 = _2993 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3020 = _3013;\n        }\n        if (_3020)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3026 = _2983 > 2;\n        bool _3033;\n        if (_3026)\n        {\n            _3033 = _2993 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3033 = _3026;\n        }\n        if (_3033)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3039 = _2983 > 3;\n        bool _3046;\n        if (_3039)\n        {\n            _3046 = _2993 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3046 = _3039;\n        }\n        if (_3046)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _4511 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _4511 = -_4511;\n    }\n    vec3 _4102 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _4511, fa_world_tangent, fa_uv, fa_vertex_color, _4102, gl_FrontFacing);\n    Surface _4110 = fa_standard_surface(param_1);\n    vec3 _4542 = _4110.albedo;\n    float _4543 = _4110.alpha;\n    vec3 _4544 = _4110.normal;\n    float _4545 = _4110.metallic;\n    float _4546 = _4110.roughness;\n    float _4547 = _4110.occlusion;\n    vec3 _4548 = _4110.emission;\n    float _4549 = _4110.clearcoat;\n    float _4550 = _4110.clearcoat_roughness;\n    vec3 _4551 = _4110.sheen_color;\n    float _4552 = _4110.sheen_roughness;\n    float _4553 = _4110.anisotropy;\n    float _4554 = _4110.anisotropy_rotation;\n    float _4555 = _4110.specular;\n    float _4556 = _4110.ior;\n    vec3 _4557 = _4110.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _4511, fa_world_tangent, fa_uv, fa_vertex_color, _4102, gl_FrontFacing);\n    Surface param_3 = _4110;\n    surface(param_2, param_3);\n    _4542 = param_3.albedo;\n    _4543 = param_3.alpha;\n    _4544 = param_3.normal;\n    _4545 = param_3.metallic;\n    _4546 = param_3.roughness;\n    _4547 = param_3.occlusion;\n    _4548 = param_3.emission;\n    _4549 = param_3.clearcoat;\n    _4550 = param_3.clearcoat_roughness;\n    _4551 = param_3.sheen_color;\n    _4552 = param_3.sheen_roughness;\n    _4553 = param_3.anisotropy;\n    _4554 = param_3.anisotropy_rotation;\n    _4555 = param_3.specular;\n    _4556 = param_3.ior;\n    _4557 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _4511;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _4542 = param_6;\n    _4544 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _4542;\n    }\n    else\n    {\n        vec3 _4148 = _4544;\n        vec3 _4149 = normalize(_4148);\n        _4544 = _4149;\n        vec3 param_8 = _4149;\n        vec3 lit = (fa_indirect_diffuse(param_8) * _4542) * _4547;\n        int _4168 = fa_cl_ndir + fa_cl_local;\n        for (int ln = 0; ln < _4168; ln++)\n        {\n            int param_9 = ln;\n            int _4181 = fa_cl_light(param_9);\n            int param_10 = _4181;\n            if (fa_baked_keep(param_10) <= 0.0)\n            {\n                continue;\n            }\n            int param_11 = _4181;\n            vec3 param_12 = fa_world_pos;\n            vec3 param_13 = _4511;\n            LightSample _4197 = fa_light_shadowed(param_11, param_12, param_13);\n            SurfaceInput param_14 = SurfaceInput(fa_world_pos, _4511, fa_world_tangent, fa_uv, fa_vertex_color, _4102, gl_FrontFacing);\n            Surface param_15 = Surface(_4542, _4543, _4544, _4545, _4546, _4547, _4548, _4549, _4550, _4551, _4552, _4553, _4554, _4555, _4556, _4557);\n            LightSample param_16 = _4197;\n            lit += light(param_14, param_15, param_16);\n        }\n        result = lit;\n    }\n    vec3 _4212 = result;\n    vec3 _4213 = _4212 + _4548;\n    result = _4213;\n    vec3 param_17 = _4213;\n    vec3 param_18 = fa_world_pos;\n    result = fa_shadow_debug(param_17, param_18);\n    bool _4222 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4229;\n    if (!_4222)\n    {\n        _4229 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4229 = _4222;\n    }\n    if (_4229)\n    {\n        vec3 _4238 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4244 = dot(_4238, fa_mesh_fs_params[9].xyz);\n        bool _4248 = fa_mesh_fs_params[9].w > 0.5;\n        float _4249;\n        if (_4248)\n        {\n            _4249 = _4244;\n        }\n        else\n        {\n            _4249 = length(_4238);\n        }\n        float _4261 = _4249 - fa_mesh_fs_params[8].x;\n        if (_4261 > 0.0)\n        {\n            float _4270 = fa_mesh_fs_params[7].w * _4261;\n            float tau = _4270 * _4270;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4286;\n                if (_4248)\n                {\n                    _4286 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4244);\n                }\n                else\n                {\n                    _4286 = fa_mesh_fs_params[0].y;\n                }\n                float _4307 = mix(_4286, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4249, 0.0, 1.0));\n                float _4311 = fa_world_pos.y - _4307;\n                float _4316 = _4307 - fa_mesh_fs_params[8].z;\n                float _4321 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _4324 = _4316 <= 0.0;\n                bool _4325 = !_4324;\n                bool _4331;\n                if (_4325)\n                {\n                    _4331 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4331 = _4324;\n                }\n                float _4332;\n                if (_4331)\n                {\n                    _4332 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _4332 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _4316, 80.0));\n                }\n                bool _4359;\n                if (_4325)\n                {\n                    _4359 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4359 = _4324;\n                }\n                float _4360;\n                if (_4359)\n                {\n                    _4360 = fa_mesh_fs_params[8].y * _4316;\n                }\n                else\n                {\n                    _4360 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4316, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _4385 = _4321 <= 0.0;\n                bool _4392;\n                if (!_4385)\n                {\n                    _4392 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _4392 = _4385;\n                }\n                float _4393;\n                if (_4392)\n                {\n                    _4393 = fa_mesh_fs_params[8].y * _4321;\n                }\n                else\n                {\n                    _4393 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _4321, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _4420;\n                if (abs(_4311) < 0.001000000047497451305389404296875)\n                {\n                    _4420 = _4332;\n                }\n                else\n                {\n                    _4420 = (_4393 - _4360) / _4311;\n                }\n                tau += (_4261 * max(_4420, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _4543);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_390",
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
            "inst_name": "_2047",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _299 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_299, 1.0);\n    fa_world_pos = _299;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _227.x;\n    _787.y = _227.y;\n    _787.z = _227.z;\n    base_t = _787;\n    vec4 _243 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _281;\n        _795.x = _286.x;\n        _795.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _315.x;\n    _798.y = _315.y;\n    _798.z = _315.z;\n    mrt = _798;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _357.y;\n            _756 *= _357.z;\n            _758 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _750, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _420 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_420, 1.0);\n    fa_world_pos = _420;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _787 = base_t;\n    _787.x = _227.x;\n    _787.y = _227.y;\n    _787.z = _227.z;\n    base_t = _787;\n    vec4 _243 = (_787 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _750 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _795 = _281;\n        _795.x = _286.x;\n        _795.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _795;\n        _750 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _798 = mrt;\n    _798.x = _315.x;\n    _798.y = _315.y;\n    _798.z = _315.z;\n    mrt = _798;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _755 = fa_mesh_fs_params[20].x;\n    float _756 = fa_mesh_fs_params[20].y;\n    float _759 = fa_mesh_fs_params[20].z;\n    float _758 = fa_mesh_fs_params[21].w;\n    float _761 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _755 *= _357.y;\n            _756 *= _357.z;\n            _758 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _759 *= mrt.x;\n            _761 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _750, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _755, _756, fa_mesh_fs_params[21].xyz, _758, _759, fa_mesh_fs_params[20].w, _761, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _661 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _661 = -_661;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _661, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
            "size": 624,
            "struct_name": "fa_mesh_fs_params",
            "inst_name": "_215",
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
    }
  }
}
