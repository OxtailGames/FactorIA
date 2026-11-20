{
  "format": "factoria.shader/1",
  "engine": "0.32.0",
  "template": "550ff47e6dc7e71192661fb1e526df6e96f66de981c805742262dd122b44bf86",
  "slang": "glsl430",
  "params": [
    "dark",
    "skyAmount"
  ],
  "textures": [],
  "programs": {
    "mesh": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _270 = _160.world_pos;\n    fa_world_pos = _270;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_270, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_shade_vertex(param, param_1, param_2, param_3, param_4, param_5);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3354[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[39];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1359 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1374;\n    if (!_1366)\n    {\n        _1374 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1374 = _1366;\n    }\n    bool _1381;\n    if (!_1374)\n    {\n        _1381 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1381 = _1374;\n    }\n    bool _1388;\n    if (!_1381)\n    {\n        _1388 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1388 = _1381;\n    }\n    if (_1388)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1398 = vec4(world_pos, 1.0);\n    float _1404 = dot(fa_mesh_fs_params[16], _1398);\n    if (!(_1404 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1426 = vec2(dot(fa_mesh_fs_params[14], _1398), dot(fa_mesh_fs_params[15], _1398)) / vec2(_1404);\n    int _1430 = int(fa_mesh_fs_params[18].x);\n    int _1434 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1434) + clamp(int(floor(((_1426.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1434 - 1)) * _1430)) + clamp(int(floor(((_1426.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1430 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1510 = fa_cluster_texel(param);\n    return ivec2(int(_1510.x), int(_1510.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4175 = fa_cluster_lookup(param);\n    fa_cl_slot = _4175.x;\n    fa_cl_local = _4175.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4552 = fa_linear_to_srgb(param);\n        c = _4552;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4560 = fa_srgb_to_linear(param_1);\n            c = _4560;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _310;\n    if (i.front_facing)\n    {\n        _310 = i.world_normal;\n    }\n    else\n    {\n        _310 = -i.world_normal;\n    }\n    vec3 _334 = normalize(i.world_tangent.xyz - (_310 * dot(_310, i.world_tangent.xyz)));\n    vec3 _362 = normalize(((_334 * m.x) + ((cross(_310, _334) * i.world_tangent.w) * m.y)) + (_310 * m.z));\n    vec3 _365;\n    if (i.front_facing)\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4591 = fa_tex_fix(param_2, param_3);\n    vec4 _5645 = base_t;\n    _5645.x = _4591.x;\n    _5645.y = _4591.y;\n    _5645.z = _4591.z;\n    base_t = _5645;\n    vec4 _4605 = (_5645 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5484 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4637 = fa_tex_fix(param_6, param_7);\n        vec3 _4640 = (_4637 * 2.0) - vec3(1.0);\n        vec2 _4645 = _4640.xy * fa_mesh_fs_params[6].x;\n        vec3 _5653 = _4640;\n        _5653.x = _4645.x;\n        _5653.y = _4645.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5653;\n        _5484 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4673 = fa_tex_fix(param_12, param_13);\n    vec4 _5656 = mrt;\n    _5656.x = _4673.x;\n    _5656.y = _4673.y;\n    _5656.z = _4673.z;\n    mrt = _5656;\n    vec4 _4701 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4701.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4712 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4742 = fa_tex_fix(param_20, param_21);\n    float _5489 = fa_mesh_fs_params[20].x;\n    float _5490 = fa_mesh_fs_params[20].y;\n    float _5493 = fa_mesh_fs_params[20].z;\n    float _5492 = fa_mesh_fs_params[21].w;\n    float _5495 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5489 *= _4712.y;\n            _5490 *= _4712.z;\n            _5492 *= _4701.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5493 *= mrt.x;\n            _5495 *= mrt.w;\n        }\n    }\n    return Surface(_4605.xyz, _4605.w, _5484, clamp(fa_mesh_fs_params[5].x * _4673.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4673.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4712.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4742), _5489, _5490, fa_mesh_fs_params[21].xyz, _5492, _5493, fa_mesh_fs_params[20].w, _5495, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1590 = rect.zw - rect.xy;\n    vec2 _1594 = _1590 * atlas;\n    vec2 _1598 = ddx * _1594;\n    vec2 _1602 = ddy * _1594;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1590), clamp(0.5 * log2(max(max(dot(_1598, _1598), dot(_1602, _1602)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1635 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1642;\n    if (!_1635)\n    {\n        _1642 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1642 = _1635;\n    }\n    if (_1642)\n    {\n        return;\n    }\n    vec3 _1648 = dFdx(world_pos);\n    vec3 _1651 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1655 = fa_cluster_texel(param);\n    int _1659 = int(_1655.w);\n    if (_1659 < 1)\n    {\n        return;\n    }\n    int _1669 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1669;\n    vec4 _1673 = fa_light_texel(param_1);\n    vec2 _1676 = _1673.yz;\n    int _1680 = int(_1673.w);\n    int param_2 = _1669 + 1;\n    vec4 _1685 = fa_light_texel(param_2);\n    float _1686 = _1685.x;\n    int _1692 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1696 = int(_1655.z);\n    vec3 _1961;\n    for (int k = 0; k < _1659; k++)\n    {\n        int _1709 = _1696 + k;\n        int param_3 = _1680 + (_1709 >> 2);\n        int _1726 = (_1669 + 2) + (int(fa_light_texel(param_3)[_1709 & 3]) * 7);\n        int param_4 = _1726 + 6;\n        vec4 _1731 = fa_light_texel(param_4);\n        if (((int(_1731.w + 0.5) >> _1692) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1726;\n        vec4 _1746 = fa_light_texel(param_5);\n        int param_6 = _1726 + 1;\n        vec4 _1751 = fa_light_texel(param_6);\n        int param_7 = _1726 + 2;\n        vec4 _1756 = fa_light_texel(param_7);\n        vec3 _1759 = _1746.xyz;\n        float _1764 = dot(_1759, world_pos) + _1746.w;\n        vec3 _1766 = _1751.xyz;\n        float _1771 = dot(_1766, world_pos) + _1751.w;\n        vec3 _1773 = _1756.xyz;\n        float _1778 = dot(_1773, world_pos) + _1756.w;\n        bool _1783 = abs(_1764) > 0.5;\n        bool _1791;\n        if (!_1783)\n        {\n            _1791 = abs(_1771) > 0.5;\n        }\n        else\n        {\n            _1791 = _1783;\n        }\n        bool _1799;\n        if (!_1791)\n        {\n            _1799 = abs(_1778) > 0.5;\n        }\n        else\n        {\n            _1799 = _1791;\n        }\n        if (_1799)\n        {\n            continue;\n        }\n        float _1814 = clamp(dot(geo_normal, normalize(_1773)) * _1731.z, 0.0, 1.0);\n        if (_1814 <= 0.0)\n        {\n            continue;\n        }\n        float _1834 = (clamp((0.5 - abs(_1778)) * 10.0, 0.0, 1.0) * _1814) * _1731.x;\n        vec2 _1842 = vec2(_1764 + 0.5, 0.5 - _1771);\n        vec2 _1852 = vec2(dot(_1759, _1648), dot(_1766, _1648));\n        vec2 _1862 = vec2(dot(_1759, _1651), dot(_1766, _1651));\n        int param_8 = _1726 + 5;\n        vec4 _1867 = fa_light_texel(param_8);\n        int param_9 = _1726 + 3;\n        vec4 _1872 = fa_light_texel(param_9);\n        int param_10 = _1726 + 4;\n        vec4 _1877 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1867.xyz;\n        bool _1887 = _1872.z > _1872.x;\n        if (_1887)\n        {\n            vec4 param_11 = _1872;\n            vec2 param_12 = _1842;\n            vec2 param_13 = _1676;\n            vec2 param_14 = _1852;\n            vec2 param_15 = _1862;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1686 > 0.5) && (_1686 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1913 = fa_dc_to_linear(param_16);\n                vec4 _5564 = tx;\n                _5564.x = _1913.x;\n                _5564.y = _1913.y;\n                _5564.z = _1913.z;\n                tx = _5564;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1834 * tex_a) * _1867.w, 0.0, 1.0)));\n        if (_1877.z > _1877.x)\n        {\n            vec4 param_17 = _1877;\n            vec2 param_18 = _1842;\n            vec2 param_19 = _1676;\n            vec2 param_20 = _1852;\n            vec2 param_21 = _1862;\n            vec4 _1957 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1686 > 1.5)\n            {\n                vec3 param_22 = _1957.xyz;\n                vec3 _1967 = fa_dc_to_srgb(param_22);\n                _1961 = _1967;\n            }\n            else\n            {\n                _1961 = _1957.xyz;\n            }\n            vec3 _1976 = (_1961 * 2.0) - vec3(1.0);\n            vec2 _1981 = _1976.xy * _1731.y;\n            vec3 _2003 = (normalize(_1759) * _1981.x) + (normalize(_1766) * _1981.y);\n            vec3 _2006 = normalize(normal);\n            normal = normalize(mix(_2006, normalize((_2006 * max(_1976.z, 0.0500000007450580596923828125)) + (_2003 - (_2006 * dot(_2006, _2003)))), vec3(clamp(_1834 * (_1887 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4145;\n    if (fa_lm.z > 0.5)\n    {\n        _4145 = 0.0;\n    }\n    else\n    {\n        _4145 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _4156 = _4145 < 1.0;\n    bool _4162;\n    if (_4156)\n    {\n        int param = li;\n        _4162 = fa_light_baked(param);\n    }\n    else\n    {\n        _4162 = _4156;\n    }\n    return _4162 ? _4145 : 1.0;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _608 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _621 = (c - (ru * hx)) - p;\n        vec3 _627 = ru * (2.0 * hx);\n        float _633 = max(dot(_627, _627), 9.9999999392252902907785028219223e-09);\n        float _637 = dot(_621, _627);\n        float t = clamp((-_637) / _633, 0.0, 1.0);\n        if (_608)\n        {\n            float _652 = dot(r, _627);\n            float _658 = _633 - (_652 * _652);\n            if (abs(_658) > (9.9999997473787516355514526367188e-06 * _633))\n            {\n                t = clamp(((dot(r, _621) * _652) - _637) / _658, 0.0, 1.0);\n            }\n        }\n        return (p + _621) + (_627 * t);\n    }\n    vec3 q = p;\n    float _690 = dot(r, axis);\n    bool _698;\n    if (_608)\n    {\n        _698 = abs(_690) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _698 = _608;\n    }\n    if (_698)\n    {\n        float _708 = dot(c - p, axis) / _690;\n        if (_708 > 0.0)\n        {\n            q = p + (r * _708);\n        }\n    }\n    vec3 _721 = q - c;\n    vec2 xy = vec2(dot(_721, ru), dot(_721, uu));\n    if (shape > 0.5)\n    {\n        float _736 = length(xy);\n        if (_736 > hx)\n        {\n            xy *= (hx / _736);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _377 = abs(d);\n    float _379 = _377.x;\n    float _381 = _377.y;\n    bool _382 = _379 >= _381;\n    bool _390;\n    if (_382)\n    {\n        _390 = _379 >= _377.z;\n    }\n    else\n    {\n        _390 = _382;\n    }\n    int _391;\n    if (_390)\n    {\n        _391 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _406;\n        if (_381 >= _377.z)\n        {\n            _406 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _406 = (d.z > 0.0) ? 4 : 5;\n        }\n        _391 = _406;\n    }\n    return _391;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _528 = dot(d, right);\n    float _532 = dot(d, up);\n    float _543;\n    if (((_528 * _528) + (_532 * _532)) > 1.0000000133514319600180897396058e-10)\n    {\n        _543 = atan(_532, _528) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _543 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_543 - floor(_543)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _774 = fa_light_base(param);\n    bool _778 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _774;\n    vec4 _782 = fa_light_texel(param_1);\n    int param_2 = _774 + 1;\n    vec4 _787 = fa_light_texel(param_2);\n    float _790 = _787.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _802 = _778 && (_790 > 2.5);\n    fa_light_is_area = _802;\n    bool _804 = _790 < 0.5;\n    vec3 l;\n    if (_804)\n    {\n        l = normalize(_782.xyz);\n        if (_778)\n        {\n            int param_3 = _774 + 6;\n            vec4 _818 = fa_light_texel(param_3);\n            if (_818.z > 0.5)\n            {\n                int param_4 = _774 + 4;\n                vec4 _828 = fa_light_texel(param_4);\n                int param_5 = _774 + 5;\n                vec4 _833 = fa_light_texel(param_5);\n                vec2 param_6 = _818.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _828.xyz) * _828.w, (-dot(world_pos, _833.xyz)) * _833.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _863 = _782.xyz;\n        vec3 _865 = _863 - world_pos;\n        vec3 to_light = _865;\n        float _868 = length(_865);\n        float reach = _868;\n        bool front = true;\n        if (_802)\n        {\n            int param_8 = _774 + 7;\n            reach = max(_868 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _774 + 4;\n            vec4 _892 = fa_light_texel(param_9);\n            int param_10 = _774 + 5;\n            vec4 _897 = fa_light_texel(param_10);\n            int param_11 = _774 + 6;\n            vec4 _902 = fa_light_texel(param_11);\n            float _903 = _902.w;\n            int param_12 = _774 + 2;\n            vec3 _910 = normalize(fa_light_texel(param_12).xyz);\n            bool _912 = _903 > 1.5;\n            bool _920;\n            if (!_912)\n            {\n                _920 = dot(_910, to_light) < 0.0;\n            }\n            else\n            {\n                _920 = _912;\n            }\n            front = _920;\n            vec3 r = vec3(0.0);\n            vec3 _929 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _933 = dot(n, n) > 0.5;\n            bool _941;\n            if (_933)\n            {\n                _941 = dot(_929, _929) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _941 = _933;\n            }\n            if (_941)\n            {\n                r = reflect(-normalize(_929), normalize(n));\n            }\n            vec3 param_13 = _863;\n            vec3 param_14 = _910;\n            vec3 param_15 = _892.xyz;\n            vec3 param_16 = _897.xyz;\n            float param_17 = _892.w;\n            float param_18 = _897.w;\n            float param_19 = _903;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _977 = length(to_light);\n        dist = _977;\n        l = to_light / vec3(max(_977, 9.9999997473787516355514526367188e-05));\n        float _991 = reach / max(_782.w, 0.001000000047497451305389404296875);\n        float _997 = clamp(1.0 - (_991 * _991), 0.0, 1.0);\n        float _999;\n        if (front)\n        {\n            _999 = _997 * _997;\n        }\n        else\n        {\n            _999 = 0.0;\n        }\n        atten = _999;\n        bool _1010 = _790 < 2.5;\n        if ((_790 > 1.5) && _1010)\n        {\n            int param_22 = _774 + 2;\n            vec4 _1018 = fa_light_texel(param_22);\n            float _1028 = _1018.w;\n            int param_23 = _774 + 3;\n            vec4 _1033 = fa_light_texel(param_23);\n            float _1034 = _1033.x;\n            float cos_inner = _1034;\n            if (_1034 > 1.5)\n            {\n                cos_inner = mix(_1028, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1028, cos_inner, dot(-l, normalize(_1018.xyz)));\n        }\n        if (_778 && (_790 < 1.5))\n        {\n            int param_24 = _774 + 6;\n            vec4 _1058 = fa_light_texel(param_24);\n            if (_1058.z > 0.5)\n            {\n                vec3 _1066 = -to_light;\n                int param_25 = _774 + 4;\n                int param_26 = _774 + 5;\n                vec3 _1080 = fa_light_texel(param_25).xyz;\n                vec3 _1084 = fa_light_texel(param_26).xyz;\n                vec3 _1093 = vec3(dot(_1066, _1080), dot(_1066, _1084), dot(_1066, cross(_1080, _1084)));\n                vec3 param_27 = _1093;\n                int _1097 = fa_cube_face(param_27);\n                int param_28 = _1097;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1124 = vec2(dot(_1093, cross(param_29, param_30)), dot(_1093, param_30)) / vec2(max(dot(_1093, param_29), 9.9999997473787516355514526367188e-05));\n                int _1128 = _1097 / 3;\n                vec2 param_31 = _1058.xy + (vec2(float(_1097 - (_1128 * 3)), float(_1128)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1124.x), 0.5 - (0.5 * _1124.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _774 + 7;\n            vec4 _1158 = fa_light_texel(param_33);\n            if (_1158.z > 0.5)\n            {\n                int param_34 = _774 + 2;\n                int param_35 = _774 + 4;\n                int param_36 = _774 + 5;\n                vec2 param_37 = _1158.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_778 && _1010)\n            {\n                int param_42 = _774 + 6;\n                vec4 _1205 = fa_light_texel(param_42);\n                int param_43 = _774 + 7;\n                vec4 _1210 = fa_light_texel(param_43);\n                bool _1213 = _1205.z > 0.5;\n                bool _1220;\n                if (!_1213)\n                {\n                    _1220 = _1210.z > 0.5;\n                }\n                else\n                {\n                    _1220 = _1213;\n                }\n                if (_1220)\n                {\n                    int param_44 = _774 + 2;\n                    vec4 _1227 = fa_light_texel(param_44);\n                    vec3 _1231 = normalize(_1227.xyz);\n                    int param_45 = _774 + 4;\n                    vec4 _1236 = fa_light_texel(param_45);\n                    int param_46 = _774 + 5;\n                    vec4 _1241 = fa_light_texel(param_46);\n                    if (_1213)\n                    {\n                        vec3 _1249 = -to_light;\n                        float _1256 = _1227.w;\n                        float _1272 = 0.5 / max(dot(_1249, _1231) * (sqrt(max(1.0 - (_1256 * _1256), 0.0)) / max(_1256, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1205.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1249, _1236.xyz) * _1272), 0.5 - (dot(_1249, _1241.xyz) * _1272));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1210.z > 0.5)\n                    {\n                        vec2 param_49 = _1210.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1231;\n                        vec3 param_52 = _1236.xyz;\n                        vec3 param_53 = _1241.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5290 = _787.xyz * atten;\n    if (_778)\n    {\n        _5290 *= fa_light_tint;\n    }\n    int _1341;\n    if (_804)\n    {\n        _1341 = 0;\n    }\n    else\n    {\n        _1341 = ((_790 > 1.5) && (_790 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5290, atten, 1.0, dist, _1341);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4374 = n < 0;\n    bool _4381;\n    if (!_4374)\n    {\n        _4381 = n >= fa_light_count();\n    }\n    else\n    {\n        _4381 = _4374;\n    }\n    if (_4381)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4389 = fa_cl_light(param);\n    int param_1 = _4389;\n    float _4393 = fa_baked_keep(param_1);\n    if (_4393 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4389;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4409 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_4409.direction, _4409.color * _4393, _4409.attenuation * _4393, _4409.shadow, _4409._distance, _4409.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2078;\n    if (i == 0)\n    {\n        _2078 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2094;\n        if (i == 1)\n        {\n            _2094 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2102;\n            if (i == 2)\n            {\n                _2102 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2102 = fa_shadows[24].w;\n            }\n            _2094 = _2102;\n        }\n        _2078 = _2094;\n    }\n    return _2078;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2135 = fa_shadow_depth(param, param_1);\n    float _2139;\n    if (conv.x < 0.5)\n    {\n        _2139 = _2135;\n    }\n    else\n    {\n        _2139 = (conv.y * conv.z) / (conv.z - (_2135 * (conv.z - conv.y)));\n    }\n    return _2139;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2066 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2066), sin(_2066)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2185 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2194;\n        if (k < 0.0)\n        {\n            _2194 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2194 = k;\n        }\n        float _2214 = clamp((_2194 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2185;\n            vec2 _2233 = fa_shadow_vogel(param_3, param_4, param_5) * _2214;\n            vec2 param_6 = uv + (_2233 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2245 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2245 < (zr - (length(_2233) * plane)))\n            {\n                sum += _2245;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2271 = sum / cnt;\n        float _2281;\n        if (k < 0.0)\n        {\n            _2281 = (-k) / max(_2271, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2281 = k;\n        }\n        radius = clamp(((max(zr - _2271, 0.0) * unit) * _2281) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2303 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2303; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2303;\n        float param_11 = _2185;\n        vec2 _2322 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2322 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2322) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2303);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2364 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2369 = clamp(dot(n, l), 0.0, 1.0);\n    float _2375 = sqrt(1.0 - (_2369 * _2369));\n    float _2382 = min(_2375 / max(_2369, 0.20000000298023223876953125), 4.0);\n    float _2387;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2387 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2387 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2412 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2387 * _2375)), 1.0);\n    float _2419 = _2412.x;\n    bool _2422 = _2419 < fa_shadows[ci * 1 + 16].x;\n    bool _2431;\n    if (!_2422)\n    {\n        _2431 = _2419 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2431 = _2422;\n    }\n    bool _2440;\n    if (!_2431)\n    {\n        _2440 = _2412.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2440 = _2431;\n    }\n    bool _2449;\n    if (!_2440)\n    {\n        _2449 = _2412.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2449 = _2440;\n    }\n    bool _2456;\n    if (!_2449)\n    {\n        _2456 = _2412.z > 1.0;\n    }\n    else\n    {\n        _2456 = _2449;\n    }\n    if (_2456)\n    {\n        return -1.0;\n    }\n    float _2464;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2464 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2464 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2412.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2412.z - ((_2464 * (1.0 + (0.5 * _2382))) / _2364);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2364;\n    float param_5 = _2364 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2382, 3.0)) * 0.5) / _2364;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2842 = int(fa_shadows[25].x + 0.5);\n    if (_2842 < 1)\n    {\n        return 1.0;\n    }\n    float _2857 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2842 - 1;\n    if (_2857 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2869 = _2842 > 1;\n    bool _2876;\n    if (_2869)\n    {\n        _2876 = _2857 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2876 = _2869;\n    }\n    if (_2876)\n    {\n        ci = 1;\n    }\n    bool _2880 = _2842 > 2;\n    bool _2887;\n    if (_2880)\n    {\n        _2887 = _2857 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2887 = _2880;\n    }\n    if (_2887)\n    {\n        ci = 2;\n    }\n    bool _2891 = _2842 > 3;\n    bool _2898;\n    if (_2891)\n    {\n        _2898 = _2857 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2898 = _2891;\n    }\n    if (_2898)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2842)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2924 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2924;\n        if (_2924 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2949;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2949 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2949 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2968 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2949, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2979 = clamp((_2857 - (fa_shadow_split_at(param_7) - _2968)) / _2968, 0.0, 1.0);\n        if (_2979 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2842)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3000 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3000;\n                if (_3000 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2979);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2522 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2529;\n    if (!_2522)\n    {\n        _2529 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2529 = _2522;\n    }\n    if (_2529)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2542 = fa_light_texel(param);\n    float _2543 = _2542.x;\n    if (_2543 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2552 = int(_2543 + 0.5);\n    int param_1 = _2552;\n    vec4 _2556 = fa_light_texel(param_1);\n    int param_2 = _2552 + 1;\n    vec4 _2561 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2564 = _2556.y;\n    if (_2564 > 0.0)\n    {\n        float _2581 = 1.0 - smoothstep(0.75 * _2564, _2564, length(world - fa_shadows[27].xyz));\n        fade = _2581;\n        if (_2581 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2556.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2605 = (_2552 + 2) + (face * 6);\n    int param_4 = _2605;\n    int param_5 = _2605 + 1;\n    int param_6 = _2605 + 3;\n    vec4 _2619 = fa_light_texel(param_6);\n    int param_7 = _2605 + 4;\n    vec4 _2624 = fa_light_texel(param_7);\n    int param_8 = _2605 + 5;\n    vec4 _2629 = fa_light_texel(param_8);\n    float _2641 = _2629.x * max(dot(_2619, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2646 = clamp(dot(n, l), 0.0, 1.0);\n    float _2669 = clamp(dot(n, _2619.xyz), -1.0, 1.0);\n    float _2688 = min(sqrt(1.0 - (_2669 * _2669)) / max(abs(dot(n, world - lpos)) / max(dot(_2619, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2691 = _2561.y;\n    float _2693;\n    if (_2691 > 0.0)\n    {\n        _2693 = _2691;\n    }\n    else\n    {\n        _2693 = 1.5 * _2641;\n    }\n    vec4 _2713 = vec4(world + (n * (_2693 * sqrt(1.0 - (_2646 * _2646)))), 1.0);\n    float _2717 = dot(_2619, _2713);\n    float _2720 = _2629.y;\n    if (_2717 < _2720)\n    {\n        return 1.0;\n    }\n    vec2 _2735 = vec2(dot(fa_light_texel(param_4), _2713), dot(fa_light_texel(param_5), _2713)) / vec2(_2717);\n    float _2737 = _2735.x;\n    bool _2740 = _2737 < _2624.x;\n    bool _2749;\n    if (!_2740)\n    {\n        _2749 = _2737 > _2624.z;\n    }\n    else\n    {\n        _2749 = _2740;\n    }\n    bool _2758;\n    if (!_2749)\n    {\n        _2758 = _2735.y < _2624.y;\n    }\n    else\n    {\n        _2758 = _2749;\n    }\n    bool _2767;\n    if (!_2758)\n    {\n        _2767 = _2735.y > _2624.w;\n    }\n    else\n    {\n        _2767 = _2758;\n    }\n    if (_2767)\n    {\n        return 1.0;\n    }\n    float _2773 = _2561.x;\n    float _2775;\n    if (_2773 > 0.0)\n    {\n        _2775 = _2773;\n    }\n    else\n    {\n        _2775 = 1.5 * _2641;\n    }\n    vec2 param_9 = _2735;\n    vec4 param_10 = _2624;\n    float param_11 = _2717 - (_2775 * (1.0 + (0.5 * _2688)));\n    float param_12 = _2641;\n    float param_13 = 1.0;\n    float param_14 = _2629.z * 0.25;\n    float param_15 = (_2641 * min(_2688, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2720, _2629.z);\n    int param_17 = int(_2556.z + 0.5);\n    float param_18 = _2556.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3889 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3896;\n    if (!_3889)\n    {\n        _3896 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3896 = _3889;\n    }\n    if (_3896)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3909 = fa_light_texel(param);\n    float _3910 = _3909.y;\n    float len = _3910;\n    if (_3910 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3922 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3932 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3922);\n    if (_3932 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3938 = len;\n    float _3941 = min(_3938, 0.89999997615814208984375 * dist);\n    len = _3941;\n    float _3946 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3922);\n    float _3951 = _3946 + (0.5 * _3941);\n    vec3 _3957 = world + (gn * _3946);\n    float _3959 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4023;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3974 = (float(k) + _3959) * 0.083333335816860198974609375;\n        vec3 _3982 = _3957 + (l * (_3974 * len));\n        vec4 _3988 = vec4(_3982, 1.0);\n        float _3994 = dot(fa_mesh_fs_params[28], _3988);\n        if (_3994 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4014 = vec2(dot(fa_mesh_fs_params[26], _3988), dot(fa_mesh_fs_params[27], _3988)) / vec2(_3994);\n        float _4018 = _4014.x * 0.5;\n        float _4019 = _4018 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4023 = (_4014.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4023 = 0.5 - (_4014.y * 0.5);\n        }\n        bool _4039 = _4019 < 0.0;\n        bool _4046;\n        if (!_4039)\n        {\n            _4046 = _4019 >= 1.0;\n        }\n        else\n        {\n            _4046 = _4039;\n        }\n        bool _4053;\n        if (!_4046)\n        {\n            _4053 = _4023 < 0.0;\n        }\n        else\n        {\n            _4053 = _4046;\n        }\n        bool _4060;\n        if (!_4053)\n        {\n            _4060 = _4023 >= 1.0;\n        }\n        else\n        {\n            _4060 = _4053;\n        }\n        if (_4060)\n        {\n            break;\n        }\n        vec4 _4079 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4019, _4023) * fa_mesh_fs_params[24].zw), 0);\n        if (_4079.w < 0.5)\n        {\n            continue;\n        }\n        float _4098 = (dot(fa_mesh_fs_params[29].xyz, _3982) + fa_mesh_fs_params[29].w) - _4079.x;\n        if ((_4098 > _3946) && (_4098 < _3951))\n        {\n            occ = max(occ, (1.0 - (_3974 * _3974)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4019, 0.5 - _4018), min(_4023, 1.0 - _4023))));\n        }\n    }\n    return 1.0 - (occ * _3932);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4201 = fa_baked_keep(param);\n    if (_4201 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4227 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5436 = _4227.color;\n    float _5437 = _4227.attenuation;\n    float _5438 = _4227.shadow;\n    bool _4230 = _4227.type == 0;\n    if (_4230 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4227.direction;\n        float _4241 = fa_shadow_factor(param_5, param_6);\n        _5438 = _4241;\n        _5436 *= _4241;\n    }\n    else\n    {\n        bool _4252 = _4227.type != 0;\n        bool _4258;\n        if (_4252)\n        {\n            _4258 = _5437 > 0.0;\n        }\n        else\n        {\n            _4258 = _4252;\n        }\n        if (_4258)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4227.direction;\n            float _4277 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5438 = _4277;\n            _5436 *= _4277;\n        }\n    }\n    bool _4287 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4293;\n    if (_4287)\n    {\n        _4293 = _5437 > 0.0;\n    }\n    else\n    {\n        _4293 = _4287;\n    }\n    if (_4293)\n    {\n        float _4300;\n        if (_4230)\n        {\n            _4300 = 1000000000.0;\n        }\n        else\n        {\n            _4300 = _4227._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4227.direction;\n        float param_18 = _4300;\n        float _4318 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5438 *= _4318;\n        _5436 *= _4318;\n    }\n    float _4331 = _5437;\n    float _4332 = _4331 * _4201;\n    _5437 = _4332;\n    vec3 _4336 = _5436;\n    vec3 _4337 = _4336 * _4201;\n    _5436 = _4337;\n    return LightSample(_4227.direction, _4337, _4332, _5438, _4227._distance, _4227.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4348 = n < 0;\n    bool _4355;\n    if (!_4348)\n    {\n        _4355 = n >= fa_light_count();\n    }\n    else\n    {\n        _4355 = _4348;\n    }\n    if (_4355)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4370 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4370;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3279 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3287 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3290 = int(_3279);\n    int _3293 = int(_3287);\n    float _3303 = _3287 - float(_3293);\n    int _3359 = (_3290 * 9) + _3293;\n    int _3379 = ((_3290 + 1) * 9) + _3293;\n    return mix(mix(_3354[_3359], _3354[_3359 + 1], _3303), mix(_3354[_3379], _3354[_3379 + 1], _3303), _3279 - float(_3290));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5302 = false;\n    float _5303 = 1.0;\n    float _5304 = 1.0;\n    float _5305 = 1.0;\n    float _5306 = 0.0;\n    float _5307 = 0.0;\n    float _5308 = 0.0;\n    float _5309 = 0.0;\n    float _5311 = 1.0;\n    bool _5312 = false;\n    vec3 _5313 = vec3(0.0);\n    float _5314 = 1.0;\n    float _5315 = 1.0;\n    float _5316 = 1.0;\n    float _5317 = 0.0;\n    float _5318 = 0.0;\n    vec3 _5319 = vec3(1.0, 0.0, 0.0);\n    vec3 _5320 = vec3(0.0, 0.0, 1.0);\n    float _5321 = 1.0;\n    float _5322 = 1.0;\n    float _3430 = clamp(s.specular, 0.0, 1.0);\n    float _3434 = clamp(s.ior, 1.0, 3.0);\n    bool _3439 = (_3430 != 1.0) || (_3434 != 1.5);\n    bool _3448;\n    if (!_3439)\n    {\n        _3448 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3448 = _3439;\n    }\n    if (_3448)\n    {\n        float _3456 = (_3434 - 1.0) / (_3434 + 1.0);\n        f0 = mix(min(vec3(_3456 * _3456) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3430, s.albedo, vec3(metallic));\n        _5303 = mix(_3430, 1.0, metallic);\n        _5302 = true;\n    }\n    float _3483 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3483 > 0.0)\n    {\n        float _3491 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5306 = _3483;\n        _5307 = _3491;\n        float _3498 = _3491 * _3491;\n        _5308 = _3498;\n        _5309 = _3498 * _3498;\n        float _3510 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5311 = _3510;\n        _5304 = 1.0 - (_3483 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3510, 0.0, 1.0), 5.0))));\n        _5302 = true;\n    }\n    vec3 _3530 = max(s.sheen_color, vec3(0.0));\n    float _3539 = max(_3530.x, max(_3530.y, _3530.z));\n    if (_3539 > 0.0)\n    {\n        float _3547 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5312 = true;\n        _5313 = _3530;\n        _5314 = _3547;\n        _5315 = _3547 * _3547;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3547;\n        float _3564 = fa_sheen_albedo(param, param_1);\n        _5317 = _3564;\n        _5316 = 1.0 - min(_3539 * _3564, 1.0);\n        _5302 = true;\n    }\n    _5305 = _5304 * _5316;\n    float _3583 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3583 != 0.0)\n    {\n        vec3 _3598 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3598;\n        if (dot(_3598, _3598) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3610 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3610.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3610.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3610.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3614 = t;\n        vec3 _3615 = normalize(_3614);\n        t = _3615;\n        vec3 _3640 = normalize((_3615 * cos(s.anisotropy_rotation)) + ((cross(n, _3615) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5319 = _3640;\n        _5320 = cross(n, _3640);\n        float _3650 = roughness * roughness;\n        float _3656 = mix(_3650, 1.0, _3583 * _3583);\n        bool _3658 = _3583 > 0.0;\n        _5321 = _3658 ? _3656 : _3650;\n        _5322 = _3658 ? _3650 : _3656;\n        _5318 = _3583;\n        _5302 = true;\n    }\n    return FaLayers(_5302, _5303, _5304, _5305, _5306, _5307, _5308, _5309, i.world_normal, _5311, _5312, _5313, _5314, _5315, _5316, _5317, _5318, _5319, _5320, _5321, _5322);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3211 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3214 = _3211.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3214 * _3214, exp2((-9.27999973297119140625) * ndv)) * _3214) + _3211.y)) + _3211.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3135 = rough * rough;\n    float _3165 = 0.60000002384185791015625 * _3135;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3135)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3165, 0.0500000007450580596923828125 + _3165, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3135 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3691;\n        if (L.aniso >= 0.0)\n        {\n            _3691 = L.b;\n        }\n        else\n        {\n            _3691 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3691, v), _3691), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3724 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3724.x) + (vec3(L.f90) * _3724.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3779 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3779.x) + _3779.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3253 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3253.x) + vec3(_3253.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3818 = clamp(s.metallic, 0.0, 1.0);\n    float _3822 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3829 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_3818));\n    vec3 f0 = _3829;\n    vec3 _3833 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3833;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _3818;\n    float param_5 = _3822;\n    vec3 param_6 = _3829;\n    FaLayers _3850 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3850.on)\n    {\n        FaLayers param_7 = _3850;\n        vec3 param_8 = _3833;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3822;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3833;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3822;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4440 = fa_light_unshadowed(param, param_1);\n        float _4448 = dot(_4440.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4448 > bestPower)\n        {\n            bestPower = _4448;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4477 = fa_light(param_2, param_3);\n        float _4485;\n        if (dot(s.normal, _4477.direction) > 0.5)\n        {\n            _4485 = 1.0;\n        }\n        else\n        {\n            _4485 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _4477.color) * _4485);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3024 = int(fa_shadows[25].x + 0.5);\n    float _3034 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3039 = _3024 > 0;\n    bool _3048;\n    if (_3039)\n    {\n        int param = _3024 - 1;\n        _3048 = _3034 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3048 = _3039;\n    }\n    if (_3048)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3054 = _3024 > 1;\n        bool _3061;\n        if (_3054)\n        {\n            _3061 = _3034 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3061 = _3054;\n        }\n        if (_3061)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3067 = _3024 > 2;\n        bool _3074;\n        if (_3067)\n        {\n            _3074 = _3034 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3074 = _3067;\n        }\n        if (_3074)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3080 = _3024 > 3;\n        bool _3087;\n        if (_3080)\n        {\n            _3087 = _3034 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3087 = _3080;\n        }\n        if (_3087)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5176 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5176 = -_5176;\n    }\n    vec3 _4863 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5176, fa_world_tangent, fa_uv, fa_vertex_color, _4863, gl_FrontFacing);\n    Surface _4871 = fa_standard_surface(param_1);\n    vec3 _5207 = _4871.albedo;\n    float _5208 = _4871.alpha;\n    vec3 _5209 = _4871.normal;\n    float _5210 = _4871.metallic;\n    float _5211 = _4871.roughness;\n    float _5212 = _4871.occlusion;\n    vec3 _5213 = _4871.emission;\n    float _5214 = _4871.clearcoat;\n    float _5215 = _4871.clearcoat_roughness;\n    vec3 _5216 = _4871.sheen_color;\n    float _5217 = _4871.sheen_roughness;\n    float _5218 = _4871.anisotropy;\n    float _5219 = _4871.anisotropy_rotation;\n    float _5220 = _4871.specular;\n    float _5221 = _4871.ior;\n    vec3 _5222 = _4871.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5176, fa_world_tangent, fa_uv, fa_vertex_color, _4863, gl_FrontFacing);\n    Surface param_3 = _4871;\n    surface(param_2, param_3);\n    _5207 = param_3.albedo;\n    _5208 = param_3.alpha;\n    _5209 = param_3.normal;\n    _5210 = param_3.metallic;\n    _5211 = param_3.roughness;\n    _5212 = param_3.occlusion;\n    _5213 = param_3.emission;\n    _5214 = param_3.clearcoat;\n    _5215 = param_3.clearcoat_roughness;\n    _5216 = param_3.sheen_color;\n    _5217 = param_3.sheen_roughness;\n    _5218 = param_3.anisotropy;\n    _5219 = param_3.anisotropy_rotation;\n    _5220 = param_3.specular;\n    _5221 = param_3.ior;\n    _5222 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5176;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5207 = param_6;\n    _5209 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5207;\n    }\n    else\n    {\n        vec3 _4909 = _5209;\n        vec3 _4910 = normalize(_4909);\n        _5209 = _4910;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5176, fa_world_tangent, fa_uv, fa_vertex_color, _4863, gl_FrontFacing);\n        Surface param_9 = Surface(_5207, _5208, _4910, _5210, _5211, _5212, _5213, _5214, _5215, _5216, _5217, _5218, _5219, _5220, _5221, _5222);\n        vec3 _4921 = lighting(param_8, param_9);\n        result = _4921;\n    }\n    vec3 _4925 = result;\n    vec3 _4926 = _4925 + _5213;\n    result = _4926;\n    vec3 param_10 = _4926;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4935 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4942;\n    if (!_4935)\n    {\n        _4942 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4942 = _4935;\n    }\n    if (_4942)\n    {\n        vec3 _4951 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4957 = dot(_4951, fa_mesh_fs_params[9].xyz);\n        bool _4961 = fa_mesh_fs_params[9].w > 0.5;\n        float _4962;\n        if (_4961)\n        {\n            _4962 = _4957;\n        }\n        else\n        {\n            _4962 = length(_4951);\n        }\n        float _4974 = _4962 - fa_mesh_fs_params[8].x;\n        if (_4974 > 0.0)\n        {\n            float _4983 = fa_mesh_fs_params[7].w * _4974;\n            float tau = _4983 * _4983;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4999;\n                if (_4961)\n                {\n                    _4999 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4957);\n                }\n                else\n                {\n                    _4999 = fa_mesh_fs_params[0].y;\n                }\n                float _5020 = mix(_4999, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4962, 0.0, 1.0));\n                float _5024 = fa_world_pos.y - _5020;\n                float _5029 = _5020 - fa_mesh_fs_params[8].z;\n                float _5034 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5037 = _5029 <= 0.0;\n                bool _5038 = !_5037;\n                bool _5044;\n                if (_5038)\n                {\n                    _5044 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5044 = _5037;\n                }\n                float _5045;\n                if (_5044)\n                {\n                    _5045 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5045 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5029, 80.0));\n                }\n                bool _5072;\n                if (_5038)\n                {\n                    _5072 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5072 = _5037;\n                }\n                float _5073;\n                if (_5072)\n                {\n                    _5073 = fa_mesh_fs_params[8].y * _5029;\n                }\n                else\n                {\n                    _5073 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5029, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5098 = _5034 <= 0.0;\n                bool _5105;\n                if (!_5098)\n                {\n                    _5105 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5105 = _5098;\n                }\n                float _5106;\n                if (_5105)\n                {\n                    _5106 = fa_mesh_fs_params[8].y * _5034;\n                }\n                else\n                {\n                    _5106 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5034, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5133;\n                if (abs(_5024) < 0.001000000047497451305389404296875)\n                {\n                    _5133 = _5045;\n                }\n                else\n                {\n                    _5133 = (_5106 - _5073) / _5024;\n                }\n                tau += (_4974 * max(_5133, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5208);\n}\n\n",
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
            "inst_name": "_430",
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
            "inst_name": "_2088",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4491",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "mesh_skin": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\nlayout(location = 5) out vec3 fa_lm;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_shade_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _391 = _273.world_pos;\n    fa_world_pos = _391;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * vec4(_391, 1.0);\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_shade_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n    fa_lm = vec3(0.0);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct LightSample\n{\n    vec3 direction;\n    vec3 color;\n    float attenuation;\n    float shadow;\n    float _distance;\n    int type;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nstruct FaLayers\n{\n    bool on;\n    float f90;\n    float keep;\n    float base_scale;\n    float coat;\n    float coat_rough;\n    float coat_alpha;\n    float coat_a2;\n    vec3 nc;\n    float coat_ndv;\n    bool sheen_on;\n    vec3 sheen;\n    float sheen_rough;\n    float sheen_alpha;\n    float sheen_scale;\n    float sheen_e;\n    float aniso;\n    vec3 t;\n    vec3 b;\n    float at;\n    float ab;\n};\n\nconst float _3354[63] = float[](1.0, 1.0, 1.0, 0.4790000021457672119140625, 0.11699999868869781494140625, 0.01200000010430812835693359375, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0.578000009059906005859375, 0.19300000369548797607421875, 0.0350000001490116119384765625, 0.0030000000260770320892333984375, 0.0, 0.0, 1.0, 1.0, 1.0, 0.6740000247955322265625, 0.3459999859333038330078125, 0.1319999992847442626953125, 0.032999999821186065673828125, 0.0040000001899898052215576171875, 0.0, 0.971000015735626220703125, 0.954999983310699462890625, 0.828999996185302734375, 0.63999998569488525390625, 0.42599999904632568359375, 0.24500000476837158203125, 0.115000002086162567138671875, 0.037000000476837158203125, 0.0030000000260770320892333984375, 0.7469999790191650390625, 0.737999975681304931640625, 0.670000016689300537109375, 0.563000023365020751953125, 0.4309999942779541015625, 0.3039999902248382568359375, 0.1940000057220458984375, 0.1019999980926513671875, 0.0309999994933605194091796875, 0.614000022411346435546875, 0.609000027179718017578125, 0.566999971866607666015625, 0.499000012874603271484375, 0.412000000476837158203125, 0.32400000095367431640625, 0.240999996662139892578125, 0.162000000476837158203125, 0.087999999523162841796875, 0.538999974727630615234375, 0.535000026226043701171875, 0.505999982357025146484375, 0.4569999873638153076171875, 0.393999993801116943359375, 0.328999996185302734375, 0.2660000026226043701171875, 0.203999996185302734375, 0.14200000464916229248046875);\n\nuniform vec4 fa_mesh_fs_params[39];\nuniform vec4 fa_shadows[30];\nuniform vec4 fa_material[2];\nlayout(binding = 0) uniform sampler2D fa_light_tex_fa_shadow_smp;\nlayout(binding = 1) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 5) uniform sampler2D fa_emissive_tex_fa_smp;\nlayout(binding = 6) uniform sampler2D fa_decal_tex_fa_env_smp;\nlayout(binding = 7) uniform sampler2D fa_light_atlas_fa_env_smp;\nlayout(binding = 8) uniform sampler2D fa_shadow_tex_fa_shadow_smp;\nlayout(binding = 9) uniform sampler2D fa_screen_tex_fa_shadow_smp;\nlayout(binding = 10) uniform samplerCube fa_env_tex_fa_env_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 5) in vec3 fa_lm;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 0) out vec4 fa_frag_color;\nvec3 fa_light_tint;\nbool fa_light_is_area;\nint fa_cl_ndir;\nint fa_cl_slot;\nint fa_cl_local;\n\nvoid fa_inst_load()\n{\n}\n\nvec4 fa_light_texel(int t)\n{\n    return texelFetch(fa_light_tex_fa_shadow_smp, ivec2(t & 1023, t >> 10), 0);\n}\n\nvec4 fa_cluster_texel(vec3 world_pos)\n{\n    bool _1359 = fa_mesh_fs_params[19].x < 0.0;\n    bool _1366;\n    if (!_1359)\n    {\n        _1366 = fa_mesh_fs_params[19].w < 1.0;\n    }\n    else\n    {\n        _1366 = _1359;\n    }\n    bool _1374;\n    if (!_1366)\n    {\n        _1374 = fa_mesh_fs_params[18].x < 1.0;\n    }\n    else\n    {\n        _1374 = _1366;\n    }\n    bool _1381;\n    if (!_1374)\n    {\n        _1381 = fa_mesh_fs_params[18].y < 1.0;\n    }\n    else\n    {\n        _1381 = _1374;\n    }\n    bool _1388;\n    if (!_1381)\n    {\n        _1388 = fa_mesh_fs_params[19].y < 1.0;\n    }\n    else\n    {\n        _1388 = _1381;\n    }\n    if (_1388)\n    {\n        return vec4(0.0);\n    }\n    vec4 _1398 = vec4(world_pos, 1.0);\n    float _1404 = dot(fa_mesh_fs_params[16], _1398);\n    if (!(_1404 > 9.9999999747524270787835121154785e-07))\n    {\n        return vec4(0.0);\n    }\n    vec2 _1426 = vec2(dot(fa_mesh_fs_params[14], _1398), dot(fa_mesh_fs_params[15], _1398)) / vec2(_1404);\n    int _1430 = int(fa_mesh_fs_params[18].x);\n    int _1434 = int(fa_mesh_fs_params[18].y);\n    int param = (int(fa_mesh_fs_params[19].x) + (((clamp(int(floor(log2(max(dot(fa_mesh_fs_params[17].xyz, world_pos) + fa_mesh_fs_params[17].w, fa_mesh_fs_params[18].w) / fa_mesh_fs_params[18].w) * fa_mesh_fs_params[18].z)), 0, int(fa_mesh_fs_params[19].y) - 1) * _1434) + clamp(int(floor(((_1426.y * 0.5) + 0.5) * fa_mesh_fs_params[18].y)), 0, _1434 - 1)) * _1430)) + clamp(int(floor(((_1426.x * 0.5) + 0.5) * fa_mesh_fs_params[18].x)), 0, _1430 - 1);\n    return fa_light_texel(param);\n}\n\nivec2 fa_cluster_lookup(vec3 world_pos)\n{\n    vec3 param = world_pos;\n    vec4 _1510 = fa_cluster_texel(param);\n    return ivec2(int(_1510.x), int(_1510.y));\n}\n\nvoid fa_cluster_begin(vec3 world_pos)\n{\n    fa_cl_ndir = int(fa_mesh_fs_params[19].z);\n    vec3 param = world_pos;\n    ivec2 _4175 = fa_cluster_lookup(param);\n    fa_cl_slot = _4175.x;\n    fa_cl_local = _4175.y;\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _4552 = fa_linear_to_srgb(param);\n        c = _4552;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _4560 = fa_srgb_to_linear(param_1);\n            c = _4560;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _310;\n    if (i.front_facing)\n    {\n        _310 = i.world_normal;\n    }\n    else\n    {\n        _310 = -i.world_normal;\n    }\n    vec3 _334 = normalize(i.world_tangent.xyz - (_310 * dot(_310, i.world_tangent.xyz)));\n    vec3 _362 = normalize(((_334 * m.x) + ((cross(_310, _334) * i.world_tangent.w) * m.y)) + (_310 * m.z));\n    vec3 _365;\n    if (i.front_facing)\n    {\n        _365 = _362;\n    }\n    else\n    {\n        _365 = -_362;\n    }\n    return _365;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _4591 = fa_tex_fix(param_2, param_3);\n    vec4 _5645 = base_t;\n    _5645.x = _4591.x;\n    _5645.y = _4591.y;\n    _5645.z = _4591.z;\n    base_t = _5645;\n    vec4 _4605 = (_5645 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _5484 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _4637 = fa_tex_fix(param_6, param_7);\n        vec3 _4640 = (_4637 * 2.0) - vec3(1.0);\n        vec2 _4645 = _4640.xy * fa_mesh_fs_params[6].x;\n        vec3 _5653 = _4640;\n        _5653.x = _4645.x;\n        _5653.y = _4645.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _5653;\n        _5484 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _4673 = fa_tex_fix(param_12, param_13);\n    vec4 _5656 = mrt;\n    _5656.x = _4673.x;\n    _5656.y = _4673.y;\n    _5656.z = _4673.z;\n    mrt = _5656;\n    vec4 _4701 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _4701.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _4712 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _4742 = fa_tex_fix(param_20, param_21);\n    float _5489 = fa_mesh_fs_params[20].x;\n    float _5490 = fa_mesh_fs_params[20].y;\n    float _5493 = fa_mesh_fs_params[20].z;\n    float _5492 = fa_mesh_fs_params[21].w;\n    float _5495 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _5489 *= _4712.y;\n            _5490 *= _4712.z;\n            _5492 *= _4701.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _5493 *= mrt.x;\n            _5495 *= mrt.w;\n        }\n    }\n    return Surface(_4605.xyz, _4605.w, _5484, clamp(fa_mesh_fs_params[5].x * _4673.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _4673.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_4712.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _4742), _5489, _5490, fa_mesh_fs_params[21].xyz, _5492, _5493, fa_mesh_fs_params[20].w, _5495, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvec4 fa_decal_tile(vec4 rect, vec2 uv, vec2 atlas, vec2 ddx, vec2 ddy)\n{\n    vec2 _1590 = rect.zw - rect.xy;\n    vec2 _1594 = _1590 * atlas;\n    vec2 _1598 = ddx * _1594;\n    vec2 _1602 = ddy * _1594;\n    return textureLod(fa_decal_tex_fa_env_smp, rect.xy + (clamp(uv, vec2(0.0), vec2(1.0)) * _1590), clamp(0.5 * log2(max(max(dot(_1598, _1598), dot(_1602, _1602)), 9.9999999392252902907785028219223e-09)), 0.0, 4.0));\n}\n\nvec3 fa_dc_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_dc_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvoid fa_apply_decals(vec3 world_pos, vec3 geo_normal, inout vec3 albedo, inout vec3 normal)\n{\n    bool _1635 = fa_mesh_fs_params[10].y < 0.5;\n    bool _1642;\n    if (!_1635)\n    {\n        _1642 = fa_mesh_fs_params[10].w < 0.5;\n    }\n    else\n    {\n        _1642 = _1635;\n    }\n    if (_1642)\n    {\n        return;\n    }\n    vec3 _1648 = dFdx(world_pos);\n    vec3 _1651 = dFdy(world_pos);\n    vec3 param = world_pos;\n    vec4 _1655 = fa_cluster_texel(param);\n    int _1659 = int(_1655.w);\n    if (_1659 < 1)\n    {\n        return;\n    }\n    int _1669 = int(fa_mesh_fs_params[10].y + 0.5);\n    int param_1 = _1669;\n    vec4 _1673 = fa_light_texel(param_1);\n    vec2 _1676 = _1673.yz;\n    int _1680 = int(_1673.w);\n    int param_2 = _1669 + 1;\n    vec4 _1685 = fa_light_texel(param_2);\n    float _1686 = _1685.x;\n    int _1692 = int(fa_mesh_fs_params[10].w + 0.5) - 1;\n    int _1696 = int(_1655.z);\n    vec3 _1961;\n    for (int k = 0; k < _1659; k++)\n    {\n        int _1709 = _1696 + k;\n        int param_3 = _1680 + (_1709 >> 2);\n        int _1726 = (_1669 + 2) + (int(fa_light_texel(param_3)[_1709 & 3]) * 7);\n        int param_4 = _1726 + 6;\n        vec4 _1731 = fa_light_texel(param_4);\n        if (((int(_1731.w + 0.5) >> _1692) & 1) == 0)\n        {\n            continue;\n        }\n        int param_5 = _1726;\n        vec4 _1746 = fa_light_texel(param_5);\n        int param_6 = _1726 + 1;\n        vec4 _1751 = fa_light_texel(param_6);\n        int param_7 = _1726 + 2;\n        vec4 _1756 = fa_light_texel(param_7);\n        vec3 _1759 = _1746.xyz;\n        float _1764 = dot(_1759, world_pos) + _1746.w;\n        vec3 _1766 = _1751.xyz;\n        float _1771 = dot(_1766, world_pos) + _1751.w;\n        vec3 _1773 = _1756.xyz;\n        float _1778 = dot(_1773, world_pos) + _1756.w;\n        bool _1783 = abs(_1764) > 0.5;\n        bool _1791;\n        if (!_1783)\n        {\n            _1791 = abs(_1771) > 0.5;\n        }\n        else\n        {\n            _1791 = _1783;\n        }\n        bool _1799;\n        if (!_1791)\n        {\n            _1799 = abs(_1778) > 0.5;\n        }\n        else\n        {\n            _1799 = _1791;\n        }\n        if (_1799)\n        {\n            continue;\n        }\n        float _1814 = clamp(dot(geo_normal, normalize(_1773)) * _1731.z, 0.0, 1.0);\n        if (_1814 <= 0.0)\n        {\n            continue;\n        }\n        float _1834 = (clamp((0.5 - abs(_1778)) * 10.0, 0.0, 1.0) * _1814) * _1731.x;\n        vec2 _1842 = vec2(_1764 + 0.5, 0.5 - _1771);\n        vec2 _1852 = vec2(dot(_1759, _1648), dot(_1766, _1648));\n        vec2 _1862 = vec2(dot(_1759, _1651), dot(_1766, _1651));\n        int param_8 = _1726 + 5;\n        vec4 _1867 = fa_light_texel(param_8);\n        int param_9 = _1726 + 3;\n        vec4 _1872 = fa_light_texel(param_9);\n        int param_10 = _1726 + 4;\n        vec4 _1877 = fa_light_texel(param_10);\n        float tex_a = 1.0;\n        vec3 col = _1867.xyz;\n        bool _1887 = _1872.z > _1872.x;\n        if (_1887)\n        {\n            vec4 param_11 = _1872;\n            vec2 param_12 = _1842;\n            vec2 param_13 = _1676;\n            vec2 param_14 = _1852;\n            vec2 param_15 = _1862;\n            vec4 tx = fa_decal_tile(param_11, param_12, param_13, param_14, param_15);\n            if ((_1686 > 0.5) && (_1686 < 1.5))\n            {\n                vec3 param_16 = tx.xyz;\n                vec3 _1913 = fa_dc_to_linear(param_16);\n                vec4 _5564 = tx;\n                _5564.x = _1913.x;\n                _5564.y = _1913.y;\n                _5564.z = _1913.z;\n                tx = _5564;\n            }\n            col *= tx.xyz;\n            tex_a = tx.w;\n        }\n        albedo = mix(albedo, col, vec3(clamp((_1834 * tex_a) * _1867.w, 0.0, 1.0)));\n        if (_1877.z > _1877.x)\n        {\n            vec4 param_17 = _1877;\n            vec2 param_18 = _1842;\n            vec2 param_19 = _1676;\n            vec2 param_20 = _1852;\n            vec2 param_21 = _1862;\n            vec4 _1957 = fa_decal_tile(param_17, param_18, param_19, param_20, param_21);\n            if (_1686 > 1.5)\n            {\n                vec3 param_22 = _1957.xyz;\n                vec3 _1967 = fa_dc_to_srgb(param_22);\n                _1961 = _1967;\n            }\n            else\n            {\n                _1961 = _1957.xyz;\n            }\n            vec3 _1976 = (_1961 * 2.0) - vec3(1.0);\n            vec2 _1981 = _1976.xy * _1731.y;\n            vec3 _2003 = (normalize(_1759) * _1981.x) + (normalize(_1766) * _1981.y);\n            vec3 _2006 = normalize(normal);\n            normal = normalize(mix(_2006, normalize((_2006 * max(_1976.z, 0.0500000007450580596923828125)) + (_2003 - (_2006 * dot(_2006, _2003)))), vec3(clamp(_1834 * (_1887 ? tex_a : 1.0), 0.0, 1.0))));\n        }\n    }\n}\n\nint fa_light_count()\n{\n    return fa_cl_ndir + fa_cl_local;\n}\n\nLightSample fa_no_light()\n{\n    return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, 0);\n}\n\nint fa_cluster_index(int slot, int n)\n{\n    int param = (int(fa_mesh_fs_params[19].x) + int(fa_mesh_fs_params[19].w)) + ((slot + n) >> 2);\n    vec4 t = fa_light_texel(param);\n    return int(t[(slot + n) & 3]);\n}\n\nint fa_cl_light(int n)\n{\n    if (n < fa_cl_ndir)\n    {\n        return n;\n    }\n    int param = fa_cl_slot;\n    int param_1 = n - fa_cl_ndir;\n    return fa_cluster_index(param, param_1);\n}\n\nint fa_light_base(int li)\n{\n    return li * ((fa_mesh_fs_params[1].w > 4.5) ? 8 : 4);\n}\n\nbool fa_light_baked(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 3;\n    return fa_light_texel(param_1).w > 0.5;\n}\n\nfloat fa_baked_keep(int li)\n{\n    float _4145;\n    if (fa_lm.z > 0.5)\n    {\n        _4145 = 0.0;\n    }\n    else\n    {\n        _4145 = 1.0 - clamp(fa_mesh_fs_params[30].w, 0.0, 1.0);\n    }\n    bool _4156 = _4145 < 1.0;\n    bool _4162;\n    if (_4156)\n    {\n        int param = li;\n        _4162 = fa_light_baked(param);\n    }\n    else\n    {\n        _4162 = _4156;\n    }\n    return _4162 ? _4145 : 1.0;\n}\n\nvec4 fa_atlas_fetch(vec2 texel)\n{\n    return textureLod(fa_light_atlas_fa_env_smp, texel / vec2(textureSize(fa_light_atlas_fa_env_smp, 0)), 0.0);\n}\n\nvec3 fa_cookie_sample(vec2 tile_origin, vec2 uv)\n{\n    vec2 param = (tile_origin + vec2(1.0)) + (clamp(uv, vec2(0.0), vec2(1.0)) * 254.0);\n    return fa_atlas_fetch(param).xyz;\n}\n\nvec3 fa_area_point(vec3 c, vec3 axis, vec3 ru, vec3 uu, float hx, float hy, float shape, vec3 p, vec3 r)\n{\n    bool _608 = dot(r, r) > 0.5;\n    if (shape > 1.5)\n    {\n        vec3 _621 = (c - (ru * hx)) - p;\n        vec3 _627 = ru * (2.0 * hx);\n        float _633 = max(dot(_627, _627), 9.9999999392252902907785028219223e-09);\n        float _637 = dot(_621, _627);\n        float t = clamp((-_637) / _633, 0.0, 1.0);\n        if (_608)\n        {\n            float _652 = dot(r, _627);\n            float _658 = _633 - (_652 * _652);\n            if (abs(_658) > (9.9999997473787516355514526367188e-06 * _633))\n            {\n                t = clamp(((dot(r, _621) * _652) - _637) / _658, 0.0, 1.0);\n            }\n        }\n        return (p + _621) + (_627 * t);\n    }\n    vec3 q = p;\n    float _690 = dot(r, axis);\n    bool _698;\n    if (_608)\n    {\n        _698 = abs(_690) > 9.9999997473787516355514526367188e-05;\n    }\n    else\n    {\n        _698 = _608;\n    }\n    if (_698)\n    {\n        float _708 = dot(c - p, axis) / _690;\n        if (_708 > 0.0)\n        {\n            q = p + (r * _708);\n        }\n    }\n    vec3 _721 = q - c;\n    vec2 xy = vec2(dot(_721, ru), dot(_721, uu));\n    if (shape > 0.5)\n    {\n        float _736 = length(xy);\n        if (_736 > hx)\n        {\n            xy *= (hx / _736);\n        }\n    }\n    else\n    {\n        xy = clamp(xy, vec2(-hx, -hy), vec2(hx, hy));\n    }\n    return (c + (ru * xy.x)) + (uu * xy.y);\n}\n\nint fa_cube_face(vec3 d)\n{\n    vec3 _377 = abs(d);\n    float _379 = _377.x;\n    float _381 = _377.y;\n    bool _382 = _379 >= _381;\n    bool _390;\n    if (_382)\n    {\n        _390 = _379 >= _377.z;\n    }\n    else\n    {\n        _390 = _382;\n    }\n    int _391;\n    if (_390)\n    {\n        _391 = (d.x > 0.0) ? 0 : 1;\n    }\n    else\n    {\n        int _406;\n        if (_381 >= _377.z)\n        {\n            _406 = (d.y > 0.0) ? 2 : 3;\n        }\n        else\n        {\n            _406 = (d.z > 0.0) ? 4 : 5;\n        }\n        _391 = _406;\n    }\n    return _391;\n}\n\nvoid fa_cube_face_basis(int f, out vec3 fwd, out vec3 up)\n{\n    if (f == 0)\n    {\n        fwd = vec3(1.0, 0.0, 0.0);\n        up = vec3(0.0, 1.0, 0.0);\n    }\n    else\n    {\n        if (f == 1)\n        {\n            fwd = vec3(-1.0, 0.0, 0.0);\n            up = vec3(0.0, 1.0, 0.0);\n        }\n        else\n        {\n            if (f == 2)\n            {\n                fwd = vec3(0.0, 1.0, 0.0);\n                up = vec3(0.0, 0.0, 1.0);\n            }\n            else\n            {\n                if (f == 3)\n                {\n                    fwd = vec3(0.0, -1.0, 0.0);\n                    up = vec3(0.0, 0.0, -1.0);\n                }\n                else\n                {\n                    if (f == 4)\n                    {\n                        fwd = vec3(0.0, 0.0, 1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                    else\n                    {\n                        fwd = vec3(0.0, 0.0, -1.0);\n                        up = vec3(0.0, 1.0, 0.0);\n                    }\n                }\n            }\n        }\n    }\n}\n\nfloat fa_ies_sample(vec2 tile_origin, vec3 d, vec3 axis, vec3 right, vec3 up)\n{\n    float _528 = dot(d, right);\n    float _532 = dot(d, up);\n    float _543;\n    if (((_528 * _528) + (_532 * _532)) > 1.0000000133514319600180897396058e-10)\n    {\n        _543 = atan(_532, _528) * 0.15915493667125701904296875;\n    }\n    else\n    {\n        _543 = 0.0;\n    }\n    vec2 param = tile_origin + vec2(1.0 + ((_543 - floor(_543)) * 64.0), 1.0 + (acos(clamp(dot(d, axis), -1.0, 1.0)) * 10.18591594696044921875));\n    return fa_atlas_fetch(param).x;\n}\n\nLightSample fa_light_sample_n(int li, vec3 world_pos, vec3 n)\n{\n    int param = li;\n    int _774 = fa_light_base(param);\n    bool _778 = fa_mesh_fs_params[1].w > 4.5;\n    int param_1 = _774;\n    vec4 _782 = fa_light_texel(param_1);\n    int param_2 = _774 + 1;\n    vec4 _787 = fa_light_texel(param_2);\n    float _790 = _787.w;\n    float atten = 1.0;\n    float dist = 0.0;\n    fa_light_tint = vec3(1.0);\n    bool _802 = _778 && (_790 > 2.5);\n    fa_light_is_area = _802;\n    bool _804 = _790 < 0.5;\n    vec3 l;\n    if (_804)\n    {\n        l = normalize(_782.xyz);\n        if (_778)\n        {\n            int param_3 = _774 + 6;\n            vec4 _818 = fa_light_texel(param_3);\n            if (_818.z > 0.5)\n            {\n                int param_4 = _774 + 4;\n                vec4 _828 = fa_light_texel(param_4);\n                int param_5 = _774 + 5;\n                vec4 _833 = fa_light_texel(param_5);\n                vec2 param_6 = _818.xy;\n                vec2 param_7 = fract(vec2(dot(world_pos, _828.xyz) * _828.w, (-dot(world_pos, _833.xyz)) * _833.w) + vec2(0.5));\n                fa_light_tint = fa_cookie_sample(param_6, param_7);\n            }\n        }\n    }\n    else\n    {\n        vec3 _863 = _782.xyz;\n        vec3 _865 = _863 - world_pos;\n        vec3 to_light = _865;\n        float _868 = length(_865);\n        float reach = _868;\n        bool front = true;\n        if (_802)\n        {\n            int param_8 = _774 + 7;\n            reach = max(_868 - fa_light_texel(param_8).w, 0.0);\n            int param_9 = _774 + 4;\n            vec4 _892 = fa_light_texel(param_9);\n            int param_10 = _774 + 5;\n            vec4 _897 = fa_light_texel(param_10);\n            int param_11 = _774 + 6;\n            vec4 _902 = fa_light_texel(param_11);\n            float _903 = _902.w;\n            int param_12 = _774 + 2;\n            vec3 _910 = normalize(fa_light_texel(param_12).xyz);\n            bool _912 = _903 > 1.5;\n            bool _920;\n            if (!_912)\n            {\n                _920 = dot(_910, to_light) < 0.0;\n            }\n            else\n            {\n                _920 = _912;\n            }\n            front = _920;\n            vec3 r = vec3(0.0);\n            vec3 _929 = fa_mesh_fs_params[0].xyz - world_pos;\n            bool _933 = dot(n, n) > 0.5;\n            bool _941;\n            if (_933)\n            {\n                _941 = dot(_929, _929) > 9.9999999600419720025001879548654e-13;\n            }\n            else\n            {\n                _941 = _933;\n            }\n            if (_941)\n            {\n                r = reflect(-normalize(_929), normalize(n));\n            }\n            vec3 param_13 = _863;\n            vec3 param_14 = _910;\n            vec3 param_15 = _892.xyz;\n            vec3 param_16 = _897.xyz;\n            float param_17 = _892.w;\n            float param_18 = _897.w;\n            float param_19 = _903;\n            vec3 param_20 = world_pos;\n            vec3 param_21 = r;\n            to_light = fa_area_point(param_13, param_14, param_15, param_16, param_17, param_18, param_19, param_20, param_21) - world_pos;\n        }\n        float _977 = length(to_light);\n        dist = _977;\n        l = to_light / vec3(max(_977, 9.9999997473787516355514526367188e-05));\n        float _991 = reach / max(_782.w, 0.001000000047497451305389404296875);\n        float _997 = clamp(1.0 - (_991 * _991), 0.0, 1.0);\n        float _999;\n        if (front)\n        {\n            _999 = _997 * _997;\n        }\n        else\n        {\n            _999 = 0.0;\n        }\n        atten = _999;\n        bool _1010 = _790 < 2.5;\n        if ((_790 > 1.5) && _1010)\n        {\n            int param_22 = _774 + 2;\n            vec4 _1018 = fa_light_texel(param_22);\n            float _1028 = _1018.w;\n            int param_23 = _774 + 3;\n            vec4 _1033 = fa_light_texel(param_23);\n            float _1034 = _1033.x;\n            float cos_inner = _1034;\n            if (_1034 > 1.5)\n            {\n                cos_inner = mix(_1028, 1.0, 0.25);\n            }\n            atten *= smoothstep(_1028, cos_inner, dot(-l, normalize(_1018.xyz)));\n        }\n        if (_778 && (_790 < 1.5))\n        {\n            int param_24 = _774 + 6;\n            vec4 _1058 = fa_light_texel(param_24);\n            if (_1058.z > 0.5)\n            {\n                vec3 _1066 = -to_light;\n                int param_25 = _774 + 4;\n                int param_26 = _774 + 5;\n                vec3 _1080 = fa_light_texel(param_25).xyz;\n                vec3 _1084 = fa_light_texel(param_26).xyz;\n                vec3 _1093 = vec3(dot(_1066, _1080), dot(_1066, _1084), dot(_1066, cross(_1080, _1084)));\n                vec3 param_27 = _1093;\n                int _1097 = fa_cube_face(param_27);\n                int param_28 = _1097;\n                vec3 param_29;\n                vec3 param_30;\n                fa_cube_face_basis(param_28, param_29, param_30);\n                vec2 _1124 = vec2(dot(_1093, cross(param_29, param_30)), dot(_1093, param_30)) / vec2(max(dot(_1093, param_29), 9.9999997473787516355514526367188e-05));\n                int _1128 = _1097 / 3;\n                vec2 param_31 = _1058.xy + (vec2(float(_1097 - (_1128 * 3)), float(_1128)) * 256.0);\n                vec2 param_32 = vec2(0.5 + (0.5 * _1124.x), 0.5 - (0.5 * _1124.y));\n                fa_light_tint = fa_cookie_sample(param_31, param_32);\n            }\n            int param_33 = _774 + 7;\n            vec4 _1158 = fa_light_texel(param_33);\n            if (_1158.z > 0.5)\n            {\n                int param_34 = _774 + 2;\n                int param_35 = _774 + 4;\n                int param_36 = _774 + 5;\n                vec2 param_37 = _1158.xy;\n                vec3 param_38 = -l;\n                vec3 param_39 = normalize(fa_light_texel(param_34).xyz);\n                vec3 param_40 = fa_light_texel(param_35).xyz;\n                vec3 param_41 = fa_light_texel(param_36).xyz;\n                atten *= fa_ies_sample(param_37, param_38, param_39, param_40, param_41);\n            }\n        }\n        else\n        {\n            if (_778 && _1010)\n            {\n                int param_42 = _774 + 6;\n                vec4 _1205 = fa_light_texel(param_42);\n                int param_43 = _774 + 7;\n                vec4 _1210 = fa_light_texel(param_43);\n                bool _1213 = _1205.z > 0.5;\n                bool _1220;\n                if (!_1213)\n                {\n                    _1220 = _1210.z > 0.5;\n                }\n                else\n                {\n                    _1220 = _1213;\n                }\n                if (_1220)\n                {\n                    int param_44 = _774 + 2;\n                    vec4 _1227 = fa_light_texel(param_44);\n                    vec3 _1231 = normalize(_1227.xyz);\n                    int param_45 = _774 + 4;\n                    vec4 _1236 = fa_light_texel(param_45);\n                    int param_46 = _774 + 5;\n                    vec4 _1241 = fa_light_texel(param_46);\n                    if (_1213)\n                    {\n                        vec3 _1249 = -to_light;\n                        float _1256 = _1227.w;\n                        float _1272 = 0.5 / max(dot(_1249, _1231) * (sqrt(max(1.0 - (_1256 * _1256), 0.0)) / max(_1256, 0.001000000047497451305389404296875)), 9.9999997473787516355514526367188e-05);\n                        vec2 param_47 = _1205.xy;\n                        vec2 param_48 = vec2(0.5 + (dot(_1249, _1236.xyz) * _1272), 0.5 - (dot(_1249, _1241.xyz) * _1272));\n                        fa_light_tint = fa_cookie_sample(param_47, param_48);\n                    }\n                    if (_1210.z > 0.5)\n                    {\n                        vec2 param_49 = _1210.xy;\n                        vec3 param_50 = -l;\n                        vec3 param_51 = _1231;\n                        vec3 param_52 = _1236.xyz;\n                        vec3 param_53 = _1241.xyz;\n                        atten *= fa_ies_sample(param_49, param_50, param_51, param_52, param_53);\n                    }\n                }\n            }\n        }\n    }\n    vec3 _5290 = _787.xyz * atten;\n    if (_778)\n    {\n        _5290 *= fa_light_tint;\n    }\n    int _1341;\n    if (_804)\n    {\n        _1341 = 0;\n    }\n    else\n    {\n        _1341 = ((_790 > 1.5) && (_790 < 2.5)) ? 2 : 1;\n    }\n    return LightSample(l, _5290, atten, 1.0, dist, _1341);\n}\n\nLightSample fa_light_unshadowed(int n, SurfaceInput i)\n{\n    bool _4374 = n < 0;\n    bool _4381;\n    if (!_4374)\n    {\n        _4381 = n >= fa_light_count();\n    }\n    else\n    {\n        _4381 = _4374;\n    }\n    if (_4381)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int _4389 = fa_cl_light(param);\n    int param_1 = _4389;\n    float _4393 = fa_baked_keep(param_1);\n    if (_4393 <= 0.0)\n    {\n        return fa_no_light();\n    }\n    int param_2 = _4389;\n    vec3 param_3 = i.world_pos;\n    vec3 param_4 = i.world_normal;\n    LightSample _4409 = fa_light_sample_n(param_2, param_3, param_4);\n    return LightSample(_4409.direction, _4409.color * _4393, _4409.attenuation * _4393, _4409.shadow, _4409._distance, _4409.type);\n}\n\nfloat fa_light_type(int li)\n{\n    int param = li;\n    int param_1 = fa_light_base(param) + 1;\n    return fa_light_texel(param_1).w;\n}\n\nfloat fa_shadow_split_at(int i)\n{\n    float _2078;\n    if (i == 0)\n    {\n        _2078 = fa_shadows[24].x;\n    }\n    else\n    {\n        float _2094;\n        if (i == 1)\n        {\n            _2094 = fa_shadows[24].y;\n        }\n        else\n        {\n            float _2102;\n            if (i == 2)\n            {\n                _2102 = fa_shadows[24].z;\n            }\n            else\n            {\n                _2102 = fa_shadows[24].w;\n            }\n            _2094 = _2102;\n        }\n        _2078 = _2094;\n    }\n    return _2078;\n}\n\nfloat fa_shadow_depth(inout vec2 uv, vec4 rect)\n{\n    uv = clamp(uv, rect.xy, rect.zw);\n    return textureLod(fa_shadow_tex_fa_shadow_smp, uv, 0.0).x;\n}\n\nfloat fa_shadow_fetch(vec2 uv, vec4 rect, vec3 conv)\n{\n    vec2 param = uv;\n    vec4 param_1 = rect;\n    float _2135 = fa_shadow_depth(param, param_1);\n    float _2139;\n    if (conv.x < 0.5)\n    {\n        _2139 = _2135;\n    }\n    else\n    {\n        _2139 = (conv.y * conv.z) / (conv.z - (_2135 * (conv.z - conv.y)));\n    }\n    return _2139;\n}\n\nfloat fa_shadow_noise()\n{\n    return fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))));\n}\n\nvec2 fa_shadow_vogel(int k, int n, float phi)\n{\n    float _2066 = (float(k) * 2.3999631404876708984375) + phi;\n    return vec2(cos(_2066), sin(_2066)) * sqrt((float(k) + 0.5) / float(n));\n}\n\nfloat fa_shadow_filter(vec2 uv, vec4 rect, float zr, float texel_m, float unit, float reach, float plane, vec3 conv, int mode, float k)\n{\n    if (mode == 1)\n    {\n        vec2 param = uv;\n        vec4 param_1 = rect;\n        vec3 param_2 = conv;\n        return float(zr <= fa_shadow_fetch(param, param_1, param_2));\n    }\n    float _2185 = fa_shadow_noise() * 6.283185482025146484375;\n    float radius = 1.5;\n    if (mode == 2)\n    {\n        float _2194;\n        if (k < 0.0)\n        {\n            _2194 = (-k) / max(zr, 0.100000001490116119384765625);\n        }\n        else\n        {\n            _2194 = k;\n        }\n        float _2214 = clamp((_2194 * reach) / texel_m, 3.0, 12.0);\n        float sum = 0.0;\n        float cnt = 0.0;\n        for (int i = 0; i < 16; i++)\n        {\n            int param_3 = i;\n            int param_4 = 16;\n            float param_5 = _2185;\n            vec2 _2233 = fa_shadow_vogel(param_3, param_4, param_5) * _2214;\n            vec2 param_6 = uv + (_2233 * fa_shadows[26].zw);\n            vec4 param_7 = rect;\n            vec3 param_8 = conv;\n            float _2245 = fa_shadow_fetch(param_6, param_7, param_8);\n            if (_2245 < (zr - (length(_2233) * plane)))\n            {\n                sum += _2245;\n                cnt += 1.0;\n            }\n        }\n        if (cnt < 0.5)\n        {\n            return 1.0;\n        }\n        float _2271 = sum / cnt;\n        float _2281;\n        if (k < 0.0)\n        {\n            _2281 = (-k) / max(_2271, 0.0500000007450580596923828125);\n        }\n        else\n        {\n            _2281 = k;\n        }\n        radius = clamp(((max(zr - _2271, 0.0) * unit) * _2281) / texel_m, 1.5, 16.0);\n    }\n    float lit = 0.0;\n    int _2303 = (mode == 2) ? 24 : 16;\n    for (int i_1 = 0; i_1 < _2303; i_1++)\n    {\n        int param_9 = i_1;\n        int param_10 = _2303;\n        float param_11 = _2185;\n        vec2 _2322 = fa_shadow_vogel(param_9, param_10, param_11) * radius;\n        vec2 param_12 = uv + (_2322 * fa_shadows[26].zw);\n        vec4 param_13 = rect;\n        vec3 param_14 = conv;\n        lit += float((zr - (length(_2322) * plane)) <= fa_shadow_fetch(param_12, param_13, param_14));\n    }\n    return lit / float(_2303);\n}\n\nfloat fa_shadow_cascade(int ci, vec3 world, vec3 n, vec3 l)\n{\n    float _2364 = max(fa_shadows[ci * 1 + 20].y, 0.001000000047497451305389404296875);\n    float _2369 = clamp(dot(n, l), 0.0, 1.0);\n    float _2375 = sqrt(1.0 - (_2369 * _2369));\n    float _2382 = min(_2375 / max(_2369, 0.20000000298023223876953125), 4.0);\n    float _2387;\n    if (fa_shadows[26].y > 0.0)\n    {\n        _2387 = fa_shadows[26].y;\n    }\n    else\n    {\n        _2387 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec4 _2412 = mat4(fa_shadows[ci * 4 + 0], fa_shadows[ci * 4 + 1], fa_shadows[ci * 4 + 2], fa_shadows[ci * 4 + 3]) * vec4(world + (n * (_2387 * _2375)), 1.0);\n    float _2419 = _2412.x;\n    bool _2422 = _2419 < fa_shadows[ci * 1 + 16].x;\n    bool _2431;\n    if (!_2422)\n    {\n        _2431 = _2419 > fa_shadows[ci * 1 + 16].z;\n    }\n    else\n    {\n        _2431 = _2422;\n    }\n    bool _2440;\n    if (!_2431)\n    {\n        _2440 = _2412.y < fa_shadows[ci * 1 + 16].y;\n    }\n    else\n    {\n        _2440 = _2431;\n    }\n    bool _2449;\n    if (!_2440)\n    {\n        _2449 = _2412.y > fa_shadows[ci * 1 + 16].w;\n    }\n    else\n    {\n        _2449 = _2440;\n    }\n    bool _2456;\n    if (!_2449)\n    {\n        _2456 = _2412.z > 1.0;\n    }\n    else\n    {\n        _2456 = _2449;\n    }\n    if (_2456)\n    {\n        return -1.0;\n    }\n    float _2464;\n    if (fa_shadows[26].x > 0.0)\n    {\n        _2464 = fa_shadows[26].x;\n    }\n    else\n    {\n        _2464 = 1.5 * fa_shadows[ci * 1 + 20].x;\n    }\n    vec2 param = _2412.xy;\n    vec4 param_1 = fa_shadows[ci * 1 + 16];\n    float param_2 = _2412.z - ((_2464 * (1.0 + (0.5 * _2382))) / _2364);\n    float param_3 = fa_shadows[ci * 1 + 20].x;\n    float param_4 = _2364;\n    float param_5 = _2364 * 0.25;\n    float param_6 = ((fa_shadows[ci * 1 + 20].x * min(_2382, 3.0)) * 0.5) / _2364;\n    vec3 param_7 = vec3(0.0);\n    int param_8 = int(fa_shadows[25].z + 0.5);\n    float param_9 = fa_shadows[25].w;\n    return fa_shadow_filter(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8, param_9);\n}\n\nfloat fa_shadow_sun(vec3 world, vec3 n, vec3 l)\n{\n    if (fa_mesh_fs_params[5].z < 0.5)\n    {\n        return 1.0;\n    }\n    int _2842 = int(fa_shadows[25].x + 0.5);\n    if (_2842 < 1)\n    {\n        return 1.0;\n    }\n    float _2857 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    int param = _2842 - 1;\n    if (_2857 > fa_shadow_split_at(param))\n    {\n        return 1.0;\n    }\n    int ci = 0;\n    bool _2869 = _2842 > 1;\n    bool _2876;\n    if (_2869)\n    {\n        _2876 = _2857 > fa_shadows[24].x;\n    }\n    else\n    {\n        _2876 = _2869;\n    }\n    if (_2876)\n    {\n        ci = 1;\n    }\n    bool _2880 = _2842 > 2;\n    bool _2887;\n    if (_2880)\n    {\n        _2887 = _2857 > fa_shadows[24].y;\n    }\n    else\n    {\n        _2887 = _2880;\n    }\n    if (_2887)\n    {\n        ci = 2;\n    }\n    bool _2891 = _2842 > 3;\n    bool _2898;\n    if (_2891)\n    {\n        _2898 = _2857 > fa_shadows[24].z;\n    }\n    else\n    {\n        _2898 = _2891;\n    }\n    if (_2898)\n    {\n        ci = 3;\n    }\n    float s = -1.0;\n    for (int k = 0; k < 4; k++)\n    {\n        if (ci >= _2842)\n        {\n            break;\n        }\n        int param_1 = ci;\n        vec3 param_2 = world;\n        vec3 param_3 = n;\n        vec3 param_4 = l;\n        float _2924 = fa_shadow_cascade(param_1, param_2, param_3, param_4);\n        s = _2924;\n        if (_2924 >= 0.0)\n        {\n            break;\n        }\n        ci++;\n    }\n    if (s < 0.0)\n    {\n        return 1.0;\n    }\n    if (fa_shadows[25].y > 0.0)\n    {\n        float _2949;\n        if (ci > 0)\n        {\n            int param_5 = ci - 1;\n            _2949 = fa_shadow_split_at(param_5);\n        }\n        else\n        {\n            _2949 = fa_shadows[28].w;\n        }\n        int param_6 = ci;\n        float _2968 = fa_shadows[25].y * max(fa_shadow_split_at(param_6) - _2949, 9.9999997473787516355514526367188e-05);\n        int param_7 = ci;\n        float _2979 = clamp((_2857 - (fa_shadow_split_at(param_7) - _2968)) / _2968, 0.0, 1.0);\n        if (_2979 > 0.0)\n        {\n            float s2 = 1.0;\n            if ((ci + 1) < _2842)\n            {\n                int param_8 = ci + 1;\n                vec3 param_9 = world;\n                vec3 param_10 = n;\n                vec3 param_11 = l;\n                float _3000 = fa_shadow_cascade(param_8, param_9, param_10, param_11);\n                s2 = _3000;\n                if (_3000 < 0.0)\n                {\n                    s2 = s;\n                }\n            }\n            s = mix(s, s2, _2979);\n        }\n    }\n    return s;\n}\n\nfloat fa_shadow_factor(vec3 n, vec3 l)\n{\n    vec3 param = fa_world_pos;\n    vec3 param_1 = n;\n    vec3 param_2 = l;\n    return fa_shadow_sun(param, param_1, param_2);\n}\n\nfloat fa_shadow_local(int li, vec3 lpos, vec3 world, vec3 n, vec3 l)\n{\n    bool _2522 = fa_mesh_fs_params[5].z < 0.5;\n    bool _2529;\n    if (!_2522)\n    {\n        _2529 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _2529 = _2522;\n    }\n    if (_2529)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _2542 = fa_light_texel(param);\n    float _2543 = _2542.x;\n    if (_2543 < 0.0)\n    {\n        return 1.0;\n    }\n    int _2552 = int(_2543 + 0.5);\n    int param_1 = _2552;\n    vec4 _2556 = fa_light_texel(param_1);\n    int param_2 = _2552 + 1;\n    vec4 _2561 = fa_light_texel(param_2);\n    float fade = 1.0;\n    float _2564 = _2556.y;\n    if (_2564 > 0.0)\n    {\n        float _2581 = 1.0 - smoothstep(0.75 * _2564, _2564, length(world - fa_shadows[27].xyz));\n        fade = _2581;\n        if (_2581 <= 0.0)\n        {\n            return 1.0;\n        }\n    }\n    int face = 0;\n    if (_2556.x > 1.5)\n    {\n        vec3 param_3 = world - lpos;\n        face = fa_cube_face(param_3);\n    }\n    int _2605 = (_2552 + 2) + (face * 6);\n    int param_4 = _2605;\n    int param_5 = _2605 + 1;\n    int param_6 = _2605 + 3;\n    vec4 _2619 = fa_light_texel(param_6);\n    int param_7 = _2605 + 4;\n    vec4 _2624 = fa_light_texel(param_7);\n    int param_8 = _2605 + 5;\n    vec4 _2629 = fa_light_texel(param_8);\n    float _2641 = _2629.x * max(dot(_2619, vec4(world, 1.0)), 0.001000000047497451305389404296875);\n    float _2646 = clamp(dot(n, l), 0.0, 1.0);\n    float _2669 = clamp(dot(n, _2619.xyz), -1.0, 1.0);\n    float _2688 = min(sqrt(1.0 - (_2669 * _2669)) / max(abs(dot(n, world - lpos)) / max(dot(_2619, vec4(world, 1.0)), 0.001000000047497451305389404296875), 0.20000000298023223876953125), 4.0);\n    float _2691 = _2561.y;\n    float _2693;\n    if (_2691 > 0.0)\n    {\n        _2693 = _2691;\n    }\n    else\n    {\n        _2693 = 1.5 * _2641;\n    }\n    vec4 _2713 = vec4(world + (n * (_2693 * sqrt(1.0 - (_2646 * _2646)))), 1.0);\n    float _2717 = dot(_2619, _2713);\n    float _2720 = _2629.y;\n    if (_2717 < _2720)\n    {\n        return 1.0;\n    }\n    vec2 _2735 = vec2(dot(fa_light_texel(param_4), _2713), dot(fa_light_texel(param_5), _2713)) / vec2(_2717);\n    float _2737 = _2735.x;\n    bool _2740 = _2737 < _2624.x;\n    bool _2749;\n    if (!_2740)\n    {\n        _2749 = _2737 > _2624.z;\n    }\n    else\n    {\n        _2749 = _2740;\n    }\n    bool _2758;\n    if (!_2749)\n    {\n        _2758 = _2735.y < _2624.y;\n    }\n    else\n    {\n        _2758 = _2749;\n    }\n    bool _2767;\n    if (!_2758)\n    {\n        _2767 = _2735.y > _2624.w;\n    }\n    else\n    {\n        _2767 = _2758;\n    }\n    if (_2767)\n    {\n        return 1.0;\n    }\n    float _2773 = _2561.x;\n    float _2775;\n    if (_2773 > 0.0)\n    {\n        _2775 = _2773;\n    }\n    else\n    {\n        _2775 = 1.5 * _2641;\n    }\n    vec2 param_9 = _2735;\n    vec4 param_10 = _2624;\n    float param_11 = _2717 - (_2775 * (1.0 + (0.5 * _2688)));\n    float param_12 = _2641;\n    float param_13 = 1.0;\n    float param_14 = _2629.z * 0.25;\n    float param_15 = (_2641 * min(_2688, 3.0)) * 0.5;\n    vec3 param_16 = vec3(1.0, _2720, _2629.z);\n    int param_17 = int(_2556.z + 0.5);\n    float param_18 = _2556.w;\n    return mix(1.0, fa_shadow_filter(param_9, param_10, param_11, param_12, param_13, param_14, param_15, param_16, param_17, param_18), fade);\n}\n\nfloat fa_contact_shadow(int li, vec3 world, vec3 gn, vec3 l, float dist)\n{\n    bool _3889 = fa_mesh_fs_params[24].x < 0.5;\n    bool _3896;\n    if (!_3889)\n    {\n        _3896 = fa_shadows[29].x < 0.5;\n    }\n    else\n    {\n        _3896 = _3889;\n    }\n    if (_3896)\n    {\n        return 1.0;\n    }\n    int param = (int(fa_shadows[29].x + 0.5) - 1) + li;\n    vec4 _3909 = fa_light_texel(param);\n    float _3910 = _3909.y;\n    float len = _3910;\n    if (_3910 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3922 = length(world - fa_mesh_fs_params[0].xyz);\n    float _3932 = 1.0 - smoothstep(0.5 * fa_mesh_fs_params[25].x, fa_mesh_fs_params[25].x, _3922);\n    if (_3932 <= 0.0)\n    {\n        return 1.0;\n    }\n    float _3938 = len;\n    float _3941 = min(_3938, 0.89999997615814208984375 * dist);\n    len = _3941;\n    float _3946 = 0.004999999888241291046142578125 + (0.0030000000260770320892333984375 * _3922);\n    float _3951 = _3946 + (0.5 * _3941);\n    vec3 _3957 = world + (gn * _3946);\n    float _3959 = fa_shadow_noise();\n    float occ = 0.0;\n    float _4023;\n    for (int k = 0; k < 12; k++)\n    {\n        float _3974 = (float(k) + _3959) * 0.083333335816860198974609375;\n        vec3 _3982 = _3957 + (l * (_3974 * len));\n        vec4 _3988 = vec4(_3982, 1.0);\n        float _3994 = dot(fa_mesh_fs_params[28], _3988);\n        if (_3994 < 9.9999997473787516355514526367188e-05)\n        {\n            break;\n        }\n        vec2 _4014 = vec2(dot(fa_mesh_fs_params[26], _3988), dot(fa_mesh_fs_params[27], _3988)) / vec2(_3994);\n        float _4018 = _4014.x * 0.5;\n        float _4019 = _4018 + 0.5;\n        if (fa_mesh_fs_params[24].y > 0.5)\n        {\n            _4023 = (_4014.y * 0.5) + 0.5;\n        }\n        else\n        {\n            _4023 = 0.5 - (_4014.y * 0.5);\n        }\n        bool _4039 = _4019 < 0.0;\n        bool _4046;\n        if (!_4039)\n        {\n            _4046 = _4019 >= 1.0;\n        }\n        else\n        {\n            _4046 = _4039;\n        }\n        bool _4053;\n        if (!_4046)\n        {\n            _4053 = _4023 < 0.0;\n        }\n        else\n        {\n            _4053 = _4046;\n        }\n        bool _4060;\n        if (!_4053)\n        {\n            _4060 = _4023 >= 1.0;\n        }\n        else\n        {\n            _4060 = _4053;\n        }\n        if (_4060)\n        {\n            break;\n        }\n        vec4 _4079 = texelFetch(fa_screen_tex_fa_shadow_smp, ivec2(vec2(_4019, _4023) * fa_mesh_fs_params[24].zw), 0);\n        if (_4079.w < 0.5)\n        {\n            continue;\n        }\n        float _4098 = (dot(fa_mesh_fs_params[29].xyz, _3982) + fa_mesh_fs_params[29].w) - _4079.x;\n        if ((_4098 > _3946) && (_4098 < _3951))\n        {\n            occ = max(occ, (1.0 - (_3974 * _3974)) * smoothstep(0.0, 0.0500000007450580596923828125, min(min(_4019, 0.5 - _4018), min(_4023, 1.0 - _4023))));\n        }\n    }\n    return 1.0 - (occ * _3932);\n}\n\nLightSample fa_light_shadowed(int li, vec3 world_pos, vec3 gn)\n{\n    int param = li;\n    float _4201 = fa_baked_keep(param);\n    if (_4201 <= 0.0)\n    {\n        int param_1 = li;\n        return LightSample(vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, 1.0, 0.0, int(fa_light_type(param_1) + 0.5));\n    }\n    int param_2 = li;\n    vec3 param_3 = world_pos;\n    vec3 param_4 = gn;\n    LightSample _4227 = fa_light_sample_n(param_2, param_3, param_4);\n    vec3 _5436 = _4227.color;\n    float _5437 = _4227.attenuation;\n    float _5438 = _4227.shadow;\n    bool _4230 = _4227.type == 0;\n    if (_4230 && (li == 0))\n    {\n        vec3 param_5 = gn;\n        vec3 param_6 = _4227.direction;\n        float _4241 = fa_shadow_factor(param_5, param_6);\n        _5438 = _4241;\n        _5436 *= _4241;\n    }\n    else\n    {\n        bool _4252 = _4227.type != 0;\n        bool _4258;\n        if (_4252)\n        {\n            _4258 = _5437 > 0.0;\n        }\n        else\n        {\n            _4258 = _4252;\n        }\n        if (_4258)\n        {\n            int param_7 = li;\n            int param_8 = fa_light_base(param_7);\n            int param_9 = li;\n            vec3 param_10 = fa_light_texel(param_8).xyz;\n            vec3 param_11 = world_pos;\n            vec3 param_12 = gn;\n            vec3 param_13 = _4227.direction;\n            float _4277 = fa_shadow_local(param_9, param_10, param_11, param_12, param_13);\n            _5438 = _4277;\n            _5436 *= _4277;\n        }\n    }\n    bool _4287 = fa_mesh_fs_params[24].x > 0.5;\n    bool _4293;\n    if (_4287)\n    {\n        _4293 = _5437 > 0.0;\n    }\n    else\n    {\n        _4293 = _4287;\n    }\n    if (_4293)\n    {\n        float _4300;\n        if (_4230)\n        {\n            _4300 = 1000000000.0;\n        }\n        else\n        {\n            _4300 = _4227._distance;\n        }\n        int param_14 = li;\n        vec3 param_15 = world_pos;\n        vec3 param_16 = gn;\n        vec3 param_17 = _4227.direction;\n        float param_18 = _4300;\n        float _4318 = fa_contact_shadow(param_14, param_15, param_16, param_17, param_18);\n        _5438 *= _4318;\n        _5436 *= _4318;\n    }\n    float _4331 = _5437;\n    float _4332 = _4331 * _4201;\n    _5437 = _4332;\n    vec3 _4336 = _5436;\n    vec3 _4337 = _4336 * _4201;\n    _5436 = _4337;\n    return LightSample(_4227.direction, _4337, _4332, _5438, _4227._distance, _4227.type);\n}\n\nLightSample fa_light(int n, SurfaceInput i)\n{\n    bool _4348 = n < 0;\n    bool _4355;\n    if (!_4348)\n    {\n        _4355 = n >= fa_light_count();\n    }\n    else\n    {\n        _4355 = _4348;\n    }\n    if (_4355)\n    {\n        return fa_no_light();\n    }\n    int param = n;\n    int param_1 = fa_cl_light(param);\n    vec3 param_2 = i.world_pos;\n    vec3 param_3 = i.world_normal;\n    LightSample _4370 = fa_light_shadowed(param_1, param_2, param_3);\n    return _4370;\n}\n\nfloat fa_sheen_albedo(float ndv, float rough)\n{\n    float _3279 = min(sqrt(max(rough - 0.100000001490116119384765625, 0.0) * 1.111111164093017578125) * 6.0, 5.999000072479248046875);\n    float _3287 = min(sqrt(clamp(ndv, 0.0, 1.0)) * 8.0, 7.999000072479248046875);\n    int _3290 = int(_3279);\n    int _3293 = int(_3287);\n    float _3303 = _3287 - float(_3293);\n    int _3359 = (_3290 * 9) + _3293;\n    int _3379 = ((_3290 + 1) * 9) + _3293;\n    return mix(mix(_3354[_3359], _3354[_3359 + 1], _3303), mix(_3354[_3379], _3354[_3379 + 1], _3303), _3279 - float(_3290));\n}\n\nFaLayers fa_layers_setup(SurfaceInput i, Surface s, vec3 n, vec3 v, float metallic, float roughness, inout vec3 f0)\n{\n    bool _5302 = false;\n    float _5303 = 1.0;\n    float _5304 = 1.0;\n    float _5305 = 1.0;\n    float _5306 = 0.0;\n    float _5307 = 0.0;\n    float _5308 = 0.0;\n    float _5309 = 0.0;\n    float _5311 = 1.0;\n    bool _5312 = false;\n    vec3 _5313 = vec3(0.0);\n    float _5314 = 1.0;\n    float _5315 = 1.0;\n    float _5316 = 1.0;\n    float _5317 = 0.0;\n    float _5318 = 0.0;\n    vec3 _5319 = vec3(1.0, 0.0, 0.0);\n    vec3 _5320 = vec3(0.0, 0.0, 1.0);\n    float _5321 = 1.0;\n    float _5322 = 1.0;\n    float _3430 = clamp(s.specular, 0.0, 1.0);\n    float _3434 = clamp(s.ior, 1.0, 3.0);\n    bool _3439 = (_3430 != 1.0) || (_3434 != 1.5);\n    bool _3448;\n    if (!_3439)\n    {\n        _3448 = any(notEqual(s.specular_color, vec3(1.0)));\n    }\n    else\n    {\n        _3448 = _3439;\n    }\n    if (_3448)\n    {\n        float _3456 = (_3434 - 1.0) / (_3434 + 1.0);\n        f0 = mix(min(vec3(_3456 * _3456) * max(s.specular_color, vec3(0.0)), vec3(1.0)) * _3430, s.albedo, vec3(metallic));\n        _5303 = mix(_3430, 1.0, metallic);\n        _5302 = true;\n    }\n    float _3483 = clamp(s.clearcoat, 0.0, 1.0);\n    if (_3483 > 0.0)\n    {\n        float _3491 = clamp(s.clearcoat_roughness, 0.0500000007450580596923828125, 1.0);\n        _5306 = _3483;\n        _5307 = _3491;\n        float _3498 = _3491 * _3491;\n        _5308 = _3498;\n        _5309 = _3498 * _3498;\n        float _3510 = max(dot(i.world_normal, v), 9.9999997473787516355514526367188e-05);\n        _5311 = _3510;\n        _5304 = 1.0 - (_3483 * (0.039999999105930328369140625 + (0.959999978542327880859375 * pow(clamp(1.0 - _3510, 0.0, 1.0), 5.0))));\n        _5302 = true;\n    }\n    vec3 _3530 = max(s.sheen_color, vec3(0.0));\n    float _3539 = max(_3530.x, max(_3530.y, _3530.z));\n    if (_3539 > 0.0)\n    {\n        float _3547 = clamp(s.sheen_roughness, 0.100000001490116119384765625, 1.0);\n        _5312 = true;\n        _5313 = _3530;\n        _5314 = _3547;\n        _5315 = _3547 * _3547;\n        float param = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n        float param_1 = _3547;\n        float _3564 = fa_sheen_albedo(param, param_1);\n        _5317 = _3564;\n        _5316 = 1.0 - min(_3539 * _3564, 1.0);\n        _5302 = true;\n    }\n    _5305 = _5304 * _5316;\n    float _3583 = clamp(s.anisotropy, -1.0, 1.0);\n    if (_3583 != 0.0)\n    {\n        vec3 _3598 = i.world_tangent.xyz - (n * dot(n, i.world_tangent.xyz));\n        vec3 t = _3598;\n        if (dot(_3598, _3598) < 9.9999999392252902907785028219223e-09)\n        {\n            bvec3 _3610 = bvec3(abs(n.y) < 0.9900000095367431640625);\n            t = cross(vec3(_3610.x ? vec3(0.0, 1.0, 0.0).x : vec3(1.0, 0.0, 0.0).x, _3610.y ? vec3(0.0, 1.0, 0.0).y : vec3(1.0, 0.0, 0.0).y, _3610.z ? vec3(0.0, 1.0, 0.0).z : vec3(1.0, 0.0, 0.0).z), n);\n        }\n        vec3 _3614 = t;\n        vec3 _3615 = normalize(_3614);\n        t = _3615;\n        vec3 _3640 = normalize((_3615 * cos(s.anisotropy_rotation)) + ((cross(n, _3615) * ((i.world_tangent.w < 0.0) ? (-1.0) : 1.0)) * sin(s.anisotropy_rotation)));\n        _5319 = _3640;\n        _5320 = cross(n, _3640);\n        float _3650 = roughness * roughness;\n        float _3656 = mix(_3650, 1.0, _3583 * _3583);\n        bool _3658 = _3583 > 0.0;\n        _5321 = _3658 ? _3656 : _3650;\n        _5322 = _3658 ? _3650 : _3656;\n        _5318 = _3583;\n        _5302 = true;\n    }\n    return FaLayers(_5302, _5303, _5304, _5305, _5306, _5307, _5308, _5309, i.world_normal, _5311, _5312, _5313, _5314, _5315, _5316, _5317, _5318, _5319, _5320, _5321, _5322);\n}\n\nvec2 fa_env_brdf(float rough, float ndv)\n{\n    vec4 _3211 = (vec4(-1.0, -0.0274999998509883880615234375, -0.572000026702880859375, 0.02199999988079071044921875) * rough) + vec4(1.0, 0.0425000004470348358154296875, 1.03999996185302734375, -0.039999999105930328369140625);\n    float _3214 = _3211.x;\n    return (vec2(-1.03999996185302734375, 1.03999996185302734375) * ((min(_3214 * _3214, exp2((-9.27999973297119140625) * ndv)) * _3214) + _3211.y)) + _3211.zw;\n}\n\nvec3 fa_environment(vec3 d, float rough)\n{\n    if (fa_mesh_fs_params[11].w > 0.5)\n    {\n        return textureLod(fa_env_tex_fa_env_smp, d, clamp(rough, 0.0, 1.0) * fa_mesh_fs_params[12].w).xyz;\n    }\n    float _3135 = rough * rough;\n    float _3165 = 0.60000002384185791015625 * _3135;\n    return mix(mix(fa_mesh_fs_params[12].xyz * 0.550000011920928955078125, mix(fa_mesh_fs_params[12].xyz, fa_mesh_fs_params[11].xyz, vec3(pow(clamp(d.y * (1.0 - (0.699999988079071044921875 * _3135)), 0.0, 1.0), 0.550000011920928955078125))), vec3(smoothstep((-0.0500000007450580596923828125) - _3165, 0.0500000007450580596923828125 + _3165, d.y))), ((fa_mesh_fs_params[11].xyz + fa_mesh_fs_params[12].xyz) * 0.5) * 0.800000011920928955078125, vec3(_3135 * 0.60000002384185791015625));\n}\n\nvec3 fa_layers_ibl(FaLayers L, vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    vec3 rn = n;\n    if (L.aniso != 0.0)\n    {\n        vec3 _3691;\n        if (L.aniso >= 0.0)\n        {\n            _3691 = L.b;\n        }\n        else\n        {\n            _3691 = L.t;\n        }\n        rn = normalize(mix(n, cross(cross(_3691, v), _3691), vec3(abs(L.aniso))));\n    }\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3724 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, rn);\n    float param_3 = roughness;\n    vec3 result = (fa_environment(param_2, param_3) * ((f0 * _3724.x) + (vec3(L.f90) * _3724.y))) * L.base_scale;\n    if (L.sheen_on)\n    {\n        vec3 param_4 = n;\n        float param_5 = L.sheen_rough;\n        result += ((L.sheen * (L.sheen_e * L.keep)) * fa_environment(param_4, param_5));\n    }\n    if (L.coat > 0.0)\n    {\n        float param_6 = L.coat_rough;\n        float param_7 = L.coat_ndv;\n        vec2 _3779 = fa_env_brdf(param_6, param_7);\n        vec3 param_8 = reflect(-v, L.nc);\n        float param_9 = L.coat_rough;\n        result += (fa_environment(param_8, param_9) * (L.coat * ((0.039999999105930328369140625 * _3779.x) + _3779.y)));\n    }\n    return result;\n}\n\nvec3 fa_sky_reflection(vec3 n, vec3 v, vec3 f0, float roughness)\n{\n    float param = roughness;\n    float param_1 = max(dot(n, v), 9.9999997473787516355514526367188e-05);\n    vec2 _3253 = fa_env_brdf(param, param_1);\n    vec3 param_2 = reflect(-v, n);\n    float param_3 = roughness;\n    return fa_environment(param_2, param_3) * ((f0 * _3253.x) + vec3(_3253.y));\n}\n\nvec3 fa_sky_light(SurfaceInput i, Surface s)\n{\n    float _3818 = clamp(s.metallic, 0.0, 1.0);\n    float _3822 = clamp(s.roughness, 0.0500000007450580596923828125, 1.0);\n    vec3 _3829 = mix(vec3(0.039999999105930328369140625), s.albedo, vec3(_3818));\n    vec3 f0 = _3829;\n    vec3 _3833 = normalize(s.normal);\n    SurfaceInput param = i;\n    Surface param_1 = s;\n    vec3 param_2 = _3833;\n    vec3 param_3 = i.view_dir;\n    float param_4 = _3818;\n    float param_5 = _3822;\n    vec3 param_6 = _3829;\n    FaLayers _3850 = fa_layers_setup(param, param_1, param_2, param_3, param_4, param_5, param_6);\n    f0 = param_6;\n    if (_3850.on)\n    {\n        FaLayers param_7 = _3850;\n        vec3 param_8 = _3833;\n        vec3 param_9 = i.view_dir;\n        vec3 param_10 = f0;\n        float param_11 = _3822;\n        return fa_layers_ibl(param_7, param_8, param_9, param_10, param_11) * s.occlusion;\n    }\n    vec3 param_12 = _3833;\n    vec3 param_13 = i.view_dir;\n    vec3 param_14 = f0;\n    float param_15 = _3822;\n    return fa_sky_reflection(param_12, param_13, param_14, param_15) * s.occlusion;\n}\n\nvec3 lighting(SurfaceInput i, Surface s)\n{\n    int best = -1;\n    float bestPower = 0.0;\n    for (int n = 0; n < fa_light_count(); n++)\n    {\n        int param = n;\n        SurfaceInput param_1 = i;\n        LightSample _4440 = fa_light_unshadowed(param, param_1);\n        float _4448 = dot(_4440.color, vec3(0.2989999949932098388671875, 0.58700001239776611328125, 0.114000000059604644775390625));\n        if (_4448 > bestPower)\n        {\n            bestPower = _4448;\n            best = n;\n        }\n    }\n    vec3 lit = (fa_mesh_fs_params[1].xyz * s.albedo) * s.occlusion;\n    if (best >= 0)\n    {\n        int param_2 = best;\n        SurfaceInput param_3 = i;\n        LightSample _4477 = fa_light(param_2, param_3);\n        float _4485;\n        if (dot(s.normal, _4477.direction) > 0.5)\n        {\n            _4485 = 1.0;\n        }\n        else\n        {\n            _4485 = fa_material[0].x;\n        }\n        lit += ((s.albedo * _4477.color) * _4485);\n    }\n    SurfaceInput param_4 = i;\n    Surface param_5 = s;\n    return lit + (fa_sky_light(param_4, param_5) * fa_material[1].x);\n}\n\nvec3 fa_shadow_debug(vec3 color, vec3 world)\n{\n    if (fa_shadows[27].w < 0.5)\n    {\n        return color;\n    }\n    int _3024 = int(fa_shadows[25].x + 0.5);\n    float _3034 = dot(world - fa_shadows[27].xyz, fa_shadows[28].xyz);\n    vec3 tint = vec3(0.3499999940395355224609375);\n    bool _3039 = _3024 > 0;\n    bool _3048;\n    if (_3039)\n    {\n        int param = _3024 - 1;\n        _3048 = _3034 <= fa_shadow_split_at(param);\n    }\n    else\n    {\n        _3048 = _3039;\n    }\n    if (_3048)\n    {\n        tint = vec3(1.0, 0.1500000059604644775390625, 0.100000001490116119384765625);\n        bool _3054 = _3024 > 1;\n        bool _3061;\n        if (_3054)\n        {\n            _3061 = _3034 > fa_shadows[24].x;\n        }\n        else\n        {\n            _3061 = _3054;\n        }\n        if (_3061)\n        {\n            tint = vec3(0.100000001490116119384765625, 0.89999997615814208984375, 0.20000000298023223876953125);\n        }\n        bool _3067 = _3024 > 2;\n        bool _3074;\n        if (_3067)\n        {\n            _3074 = _3034 > fa_shadows[24].y;\n        }\n        else\n        {\n            _3074 = _3067;\n        }\n        if (_3074)\n        {\n            tint = vec3(0.1500000059604644775390625, 0.300000011920928955078125, 1.0);\n        }\n        bool _3080 = _3024 > 3;\n        bool _3087;\n        if (_3080)\n        {\n            _3087 = _3034 > fa_shadows[24].z;\n        }\n        else\n        {\n            _3087 = _3080;\n        }\n        if (_3087)\n        {\n            tint = vec3(1.0, 0.89999997615814208984375, 0.100000001490116119384765625);\n        }\n    }\n    return mix(color, tint, vec3(0.550000011920928955078125));\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _5176 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _5176 = -_5176;\n    }\n    vec3 _4863 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    vec3 param = fa_world_pos;\n    fa_cluster_begin(param);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _5176, fa_world_tangent, fa_uv, fa_vertex_color, _4863, gl_FrontFacing);\n    Surface _4871 = fa_standard_surface(param_1);\n    vec3 _5207 = _4871.albedo;\n    float _5208 = _4871.alpha;\n    vec3 _5209 = _4871.normal;\n    float _5210 = _4871.metallic;\n    float _5211 = _4871.roughness;\n    float _5212 = _4871.occlusion;\n    vec3 _5213 = _4871.emission;\n    float _5214 = _4871.clearcoat;\n    float _5215 = _4871.clearcoat_roughness;\n    vec3 _5216 = _4871.sheen_color;\n    float _5217 = _4871.sheen_roughness;\n    float _5218 = _4871.anisotropy;\n    float _5219 = _4871.anisotropy_rotation;\n    float _5220 = _4871.specular;\n    float _5221 = _4871.ior;\n    vec3 _5222 = _4871.specular_color;\n    SurfaceInput param_2 = SurfaceInput(fa_world_pos, _5176, fa_world_tangent, fa_uv, fa_vertex_color, _4863, gl_FrontFacing);\n    Surface param_3 = _4871;\n    surface(param_2, param_3);\n    _5207 = param_3.albedo;\n    _5208 = param_3.alpha;\n    _5209 = param_3.normal;\n    _5210 = param_3.metallic;\n    _5211 = param_3.roughness;\n    _5212 = param_3.occlusion;\n    _5213 = param_3.emission;\n    _5214 = param_3.clearcoat;\n    _5215 = param_3.clearcoat_roughness;\n    _5216 = param_3.sheen_color;\n    _5217 = param_3.sheen_roughness;\n    _5218 = param_3.anisotropy;\n    _5219 = param_3.anisotropy_rotation;\n    _5220 = param_3.specular;\n    _5221 = param_3.ior;\n    _5222 = param_3.specular_color;\n    vec3 param_4 = fa_world_pos;\n    vec3 param_5 = _5176;\n    vec3 param_6 = param_3.albedo;\n    vec3 param_7 = param_3.normal;\n    fa_apply_decals(param_4, param_5, param_6, param_7);\n    _5207 = param_6;\n    _5209 = param_7;\n    vec3 result;\n    if (fa_mesh_fs_params[3].w > 0.5)\n    {\n        result = _5207;\n    }\n    else\n    {\n        vec3 _4909 = _5209;\n        vec3 _4910 = normalize(_4909);\n        _5209 = _4910;\n        SurfaceInput param_8 = SurfaceInput(fa_world_pos, _5176, fa_world_tangent, fa_uv, fa_vertex_color, _4863, gl_FrontFacing);\n        Surface param_9 = Surface(_5207, _5208, _4910, _5210, _5211, _5212, _5213, _5214, _5215, _5216, _5217, _5218, _5219, _5220, _5221, _5222);\n        vec3 _4921 = lighting(param_8, param_9);\n        result = _4921;\n    }\n    vec3 _4925 = result;\n    vec3 _4926 = _4925 + _5213;\n    result = _4926;\n    vec3 param_10 = _4926;\n    vec3 param_11 = fa_world_pos;\n    result = fa_shadow_debug(param_10, param_11);\n    bool _4935 = fa_mesh_fs_params[7].w > 0.0;\n    bool _4942;\n    if (!_4935)\n    {\n        _4942 = fa_mesh_fs_params[8].y > 0.0;\n    }\n    else\n    {\n        _4942 = _4935;\n    }\n    if (_4942)\n    {\n        vec3 _4951 = fa_world_pos - fa_mesh_fs_params[0].xyz;\n        float _4957 = dot(_4951, fa_mesh_fs_params[9].xyz);\n        bool _4961 = fa_mesh_fs_params[9].w > 0.5;\n        float _4962;\n        if (_4961)\n        {\n            _4962 = _4957;\n        }\n        else\n        {\n            _4962 = length(_4951);\n        }\n        float _4974 = _4962 - fa_mesh_fs_params[8].x;\n        if (_4974 > 0.0)\n        {\n            float _4983 = fa_mesh_fs_params[7].w * _4974;\n            float tau = _4983 * _4983;\n            if (fa_mesh_fs_params[8].y > 0.0)\n            {\n                float _4999;\n                if (_4961)\n                {\n                    _4999 = fa_world_pos.y - (fa_mesh_fs_params[9].y * _4957);\n                }\n                else\n                {\n                    _4999 = fa_mesh_fs_params[0].y;\n                }\n                float _5020 = mix(_4999, fa_world_pos.y, clamp(fa_mesh_fs_params[8].x / _4962, 0.0, 1.0));\n                float _5024 = fa_world_pos.y - _5020;\n                float _5029 = _5020 - fa_mesh_fs_params[8].z;\n                float _5034 = fa_world_pos.y - fa_mesh_fs_params[8].z;\n                bool _5037 = _5029 <= 0.0;\n                bool _5038 = !_5037;\n                bool _5044;\n                if (_5038)\n                {\n                    _5044 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5044 = _5037;\n                }\n                float _5045;\n                if (_5044)\n                {\n                    _5045 = fa_mesh_fs_params[8].y;\n                }\n                else\n                {\n                    _5045 = fa_mesh_fs_params[8].y * exp(-min(fa_mesh_fs_params[8].w * _5029, 80.0));\n                }\n                bool _5072;\n                if (_5038)\n                {\n                    _5072 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5072 = _5037;\n                }\n                float _5073;\n                if (_5072)\n                {\n                    _5073 = fa_mesh_fs_params[8].y * _5029;\n                }\n                else\n                {\n                    _5073 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5029, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                bool _5098 = _5034 <= 0.0;\n                bool _5105;\n                if (!_5098)\n                {\n                    _5105 = fa_mesh_fs_params[8].w < 9.9999997473787516355514526367188e-05;\n                }\n                else\n                {\n                    _5105 = _5098;\n                }\n                float _5106;\n                if (_5105)\n                {\n                    _5106 = fa_mesh_fs_params[8].y * _5034;\n                }\n                else\n                {\n                    _5106 = (fa_mesh_fs_params[8].y * (1.0 - exp(-min(fa_mesh_fs_params[8].w * _5034, 80.0)))) / fa_mesh_fs_params[8].w;\n                }\n                float _5133;\n                if (abs(_5024) < 0.001000000047497451305389404296875)\n                {\n                    _5133 = _5045;\n                }\n                else\n                {\n                    _5133 = (_5106 - _5073) / _5024;\n                }\n                tau += (_4974 * max(_5133, 0.0));\n            }\n            result = mix(result, fa_mesh_fs_params[7].xyz, vec3(clamp(1.0 - exp(-clamp(tau, 0.0, 80.0)), 0.0, 1.0)));\n        }\n    }\n    fa_frag_color = vec4(result, _5208);\n}\n\n",
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
            "inst_name": "_430",
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
            "inst_name": "_2088",
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
            "size": 32,
            "struct_name": "fa_material",
            "inst_name": "_4491",
            "glsl_uniforms": [
              {
                "type": "vec4",
                "array_count": 2,
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
            "name": "fa_light_atlas_fa_env_smp",
            "view_name": "fa_light_atlas",
            "sampler_name": "fa_env_smp",
            "view_slot": 25,
            "sampler_slot": 10,
            "glsl_name": "fa_light_atlas_fa_env_smp"
          },
          {
            "slot": 8,
            "stage": "fragment",
            "name": "fa_shadow_tex_fa_shadow_smp",
            "view_name": "fa_shadow_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 1,
            "sampler_slot": 1,
            "glsl_name": "fa_shadow_tex_fa_shadow_smp"
          },
          {
            "slot": 9,
            "stage": "fragment",
            "name": "fa_screen_tex_fa_shadow_smp",
            "view_name": "fa_screen_tex",
            "sampler_name": "fa_shadow_smp",
            "view_slot": 28,
            "sampler_slot": 1,
            "glsl_name": "fa_screen_tex_fa_shadow_smp"
          },
          {
            "slot": 10,
            "stage": "fragment",
            "name": "fa_env_tex_fa_env_smp",
            "view_name": "fa_env_tex",
            "sampler_name": "fa_env_smp",
            "view_slot": 14,
            "sampler_slot": 10,
            "glsl_name": "fa_env_tex_fa_env_smp"
          }
        ]
      }
    },
    "prepass": {
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _69 = cross(model[1].xyz, model[2].xyz);\n    float _75 = (dot(model[0].xyz, _69) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_69 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _75, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _75), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _160 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _302 = _160.world_pos;\n    mat4 _164 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _171 = vec4(_302, 1.0);\n    fa_world_pos = _302;\n    fa_world_normal = _160.world_normal;\n    fa_world_tangent = _160.world_tangent;\n    fa_uv = _160.uv;\n    fa_vertex_color = _160.color;\n    fa_pre_depth = -(_164 * _171).z;\n    fa_pre_r0 = vec3(_164[0].x, _164[1].x, _164[2].x);\n    fa_pre_r1 = vec3(_164[0].y, _164[1].y, _164[2].y);\n    fa_pre_r2 = vec3(_164[0].z, _164[1].z, _164[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _171;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    mat4 param = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3);\n    vec3 param_1 = fa_position;\n    vec3 param_2 = fa_normal;\n    vec4 param_3 = fa_tangent;\n    vec2 param_4 = fa_texcoord0;\n    vec4 param_5 = fa_color;\n    fa_prepass_vertex(param, param_1, param_2, param_3, param_4, param_5);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _790 = base_t;\n    _790.x = _227.x;\n    _790.y = _227.y;\n    _790.z = _227.z;\n    base_t = _790;\n    vec4 _243 = (_790 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _753 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _798 = _281;\n        _798.x = _286.x;\n        _798.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _798;\n        _753 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _801 = mrt;\n    _801.x = _315.x;\n    _801.y = _315.y;\n    _801.z = _315.z;\n    mrt = _801;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _758 = fa_mesh_fs_params[20].x;\n    float _759 = fa_mesh_fs_params[20].y;\n    float _762 = fa_mesh_fs_params[20].z;\n    float _761 = fa_mesh_fs_params[21].w;\n    float _764 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _758 *= _357.y;\n            _759 *= _357.z;\n            _761 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _762 *= mrt.x;\n            _764 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _753, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _758, _759, fa_mesh_fs_params[21].xyz, _761, _762, fa_mesh_fs_params[20].w, _764, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _664 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _664 = -_664;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _664, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _664, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
      "vs": "#version 430\n\nstruct VertexData\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 color;\n    vec3 object_pos;\n};\n\nuniform vec4 fa_mesh_vs_params[11];\nuniform vec4 fa_skin[192];\nlayout(location = 0) out vec3 fa_world_pos;\nlayout(location = 1) out vec3 fa_world_normal;\nlayout(location = 2) out vec4 fa_world_tangent;\nlayout(location = 3) out vec2 fa_uv;\nlayout(location = 4) out vec4 fa_vertex_color;\nlayout(location = 5) out float fa_pre_depth;\nlayout(location = 6) out vec3 fa_pre_r0;\nlayout(location = 7) out vec3 fa_pre_r1;\nlayout(location = 8) out vec3 fa_pre_r2;\nlayout(location = 5) in vec4 fa_inst_m0;\nlayout(location = 6) in vec4 fa_inst_m1;\nlayout(location = 7) in vec4 fa_inst_m2;\nlayout(location = 8) in vec4 fa_inst_m3;\nlayout(location = 9) in vec4 fa_joints;\nlayout(location = 10) in vec4 fa_weights;\nlayout(location = 0) in vec3 fa_position;\nlayout(location = 1) in vec3 fa_normal;\nlayout(location = 3) in vec4 fa_tangent;\nlayout(location = 2) in vec2 fa_texcoord0;\nlayout(location = 4) in vec4 fa_color;\n\nvoid fa_inst_begin()\n{\n}\n\nmat4 fa_skin_matrix(vec4 joints, vec4 weights)\n{\n    vec4 r0 = vec4(0.0);\n    vec4 r1 = vec4(0.0);\n    vec4 r2 = vec4(0.0);\n    for (int i = 0; i < 4; i++)\n    {\n        int _174 = int((joints[i] * 255.0) + 0.5) * 3;\n        r0 += (fa_skin[_174 * 1 + 0] * weights[i]);\n        r1 += (fa_skin[(_174 + 1) * 1 + 0] * weights[i]);\n        r2 += (fa_skin[(_174 + 2) * 1 + 0] * weights[i]);\n    }\n    return mat4(vec4(r0.x, r1.x, r2.x, 0.0), vec4(r0.y, r1.y, r2.y, 0.0), vec4(r0.z, r1.z, r2.z, 0.0), vec4(r0.w, r1.w, r2.w, 1.0));\n}\n\nVertexData fa_vertex_data(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    vec3 _74 = cross(model[1].xyz, model[2].xyz);\n    float _80 = (dot(model[0].xyz, _74) < 0.0) ? (-1.0) : 1.0;\n    return VertexData((model * vec4(position, 1.0)).xyz, (((_74 * normal.x) + (cross(model[2].xyz, model[0].xyz) * normal.y)) + (cross(model[0].xyz, model[1].xyz) * normal.z)) * _80, vec4(((model[0].xyz * tangent.x) + (model[1].xyz * tangent.y)) + (model[2].xyz * tangent.z), tangent.w * _80), texcoord0 * fa_mesh_vs_params[8].xy, color, position);\n}\n\nvoid fa_prepass_vertex(mat4 model, vec3 position, vec3 normal, vec4 tangent, vec2 texcoord0, vec4 color)\n{\n    mat4 param = model;\n    vec3 param_1 = position;\n    vec3 param_2 = normal;\n    vec4 param_3 = tangent;\n    vec2 param_4 = texcoord0;\n    vec4 param_5 = color;\n    VertexData _273 = fa_vertex_data(param, param_1, param_2, param_3, param_4, param_5);\n    vec3 _423 = _273.world_pos;\n    mat4 _277 = mat4(fa_mesh_vs_params[4], fa_mesh_vs_params[5], fa_mesh_vs_params[6], fa_mesh_vs_params[7]);\n    vec4 _284 = vec4(_423, 1.0);\n    fa_world_pos = _423;\n    fa_world_normal = _273.world_normal;\n    fa_world_tangent = _273.world_tangent;\n    fa_uv = _273.uv;\n    fa_vertex_color = _273.color;\n    fa_pre_depth = -(_277 * _284).z;\n    fa_pre_r0 = vec3(_277[0].x, _277[1].x, _277[2].x);\n    fa_pre_r1 = vec3(_277[0].y, _277[1].y, _277[2].y);\n    fa_pre_r2 = vec3(_277[0].z, _277[1].z, _277[2].z);\n    gl_Position = mat4(fa_mesh_vs_params[0], fa_mesh_vs_params[1], fa_mesh_vs_params[2], fa_mesh_vs_params[3]) * _284;\n}\n\nvoid main()\n{\n    fa_inst_begin();\n    vec4 param = fa_joints;\n    vec4 param_1 = fa_weights;\n    mat4 param_2 = mat4(fa_inst_m0, fa_inst_m1, fa_inst_m2, fa_inst_m3) * fa_skin_matrix(param, param_1);\n    vec3 param_3 = fa_position;\n    vec3 param_4 = fa_normal;\n    vec4 param_5 = fa_tangent;\n    vec2 param_6 = fa_texcoord0;\n    vec4 param_7 = fa_color;\n    fa_prepass_vertex(param_2, param_3, param_4, param_5, param_6, param_7);\n}\n\n",
      "fs": "#version 430\n\nstruct SurfaceInput\n{\n    vec3 world_pos;\n    vec3 world_normal;\n    vec4 world_tangent;\n    vec2 uv;\n    vec4 vertex_color;\n    vec3 view_dir;\n    bool front_facing;\n};\n\nstruct Surface\n{\n    vec3 albedo;\n    float alpha;\n    vec3 normal;\n    float metallic;\n    float roughness;\n    float occlusion;\n    vec3 emission;\n    float clearcoat;\n    float clearcoat_roughness;\n    vec3 sheen_color;\n    float sheen_roughness;\n    float anisotropy;\n    float anisotropy_rotation;\n    float specular;\n    float ior;\n    vec3 specular_color;\n};\n\nuniform vec4 fa_mesh_fs_params[39];\nlayout(binding = 0) uniform sampler2D fa_tex_fa_smp;\nlayout(binding = 1) uniform sampler2D fa_normal_tex_fa_smp;\nlayout(binding = 2) uniform sampler2D fa_mr_tex_fa_smp;\nlayout(binding = 3) uniform sampler2D fa_occlusion_tex_fa_smp;\nlayout(binding = 4) uniform sampler2D fa_emissive_tex_fa_smp;\n\nlayout(location = 0) in vec3 fa_world_pos;\nlayout(location = 1) in vec3 fa_world_normal;\nlayout(location = 2) in vec4 fa_world_tangent;\nlayout(location = 3) in vec2 fa_uv;\nlayout(location = 4) in vec4 fa_vertex_color;\nlayout(location = 6) in vec3 fa_pre_r0;\nlayout(location = 7) in vec3 fa_pre_r1;\nlayout(location = 8) in vec3 fa_pre_r2;\nlayout(location = 0) out vec4 fa_frag_color;\nlayout(location = 5) in float fa_pre_depth;\n\nvoid fa_inst_load()\n{\n}\n\nfloat fa_fix_of(float _packed, float scale)\n{\n    return mod(floor((_packed / scale) + 0.00999999977648258209228515625), 4.0);\n}\n\nvec3 fa_linear_to_srgb(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix((pow(c, vec3(0.4166666567325592041015625)) * 1.05499994754791259765625) - vec3(0.054999999701976776123046875), c * 12.9200000762939453125, step(c, vec3(0.003130800090730190277099609375)));\n}\n\nvec3 fa_srgb_to_linear(inout vec3 c)\n{\n    c = max(c, vec3(0.0));\n    return mix(pow((c + vec3(0.054999999701976776123046875)) * vec3(0.947867333889007568359375), vec3(2.400000095367431640625)), c * vec3(0.077399380505084991455078125), step(c, vec3(0.040449999272823333740234375)));\n}\n\nvec3 fa_tex_fix(inout vec3 c, float mode)\n{\n    if (mode > 1.5)\n    {\n        vec3 param = c;\n        vec3 _172 = fa_linear_to_srgb(param);\n        c = _172;\n    }\n    else\n    {\n        if (mode > 0.5)\n        {\n            vec3 param_1 = c;\n            vec3 _181 = fa_srgb_to_linear(param_1);\n            c = _181;\n        }\n    }\n    return c;\n}\n\nvec3 fa_tangent_normal(SurfaceInput i, vec3 m)\n{\n    vec3 _56;\n    if (i.front_facing)\n    {\n        _56 = i.world_normal;\n    }\n    else\n    {\n        _56 = -i.world_normal;\n    }\n    vec3 _81 = normalize(i.world_tangent.xyz - (_56 * dot(_56, i.world_tangent.xyz)));\n    vec3 _109 = normalize(((_81 * m.x) + ((cross(_56, _81) * i.world_tangent.w) * m.y)) + (_56 * m.z));\n    vec3 _112;\n    if (i.front_facing)\n    {\n        _112 = _109;\n    }\n    else\n    {\n        _112 = -_109;\n    }\n    return _112;\n}\n\nSurface fa_standard_surface(SurfaceInput i)\n{\n    vec4 base_t = texture(fa_tex_fa_smp, i.uv);\n    float param = fa_mesh_fs_params[6].w;\n    float param_1 = 1.0;\n    vec3 param_2 = base_t.xyz;\n    float param_3 = fa_fix_of(param, param_1);\n    vec3 _227 = fa_tex_fix(param_2, param_3);\n    vec4 _790 = base_t;\n    _790.x = _227.x;\n    _790.y = _227.y;\n    _790.z = _227.z;\n    base_t = _790;\n    vec4 _243 = (_790 * fa_mesh_fs_params[2]) * i.vertex_color;\n    vec3 _753 = i.world_normal;\n    if (fa_mesh_fs_params[6].z > 0.5)\n    {\n        float param_4 = fa_mesh_fs_params[6].w;\n        float param_5 = 16.0;\n        vec3 param_6 = texture(fa_normal_tex_fa_smp, i.uv).xyz;\n        float param_7 = fa_fix_of(param_4, param_5);\n        vec3 _277 = fa_tex_fix(param_6, param_7);\n        vec3 _281 = (_277 * 2.0) - vec3(1.0);\n        vec2 _286 = _281.xy * fa_mesh_fs_params[6].x;\n        vec3 _798 = _281;\n        _798.x = _286.x;\n        _798.y = _286.y;\n        SurfaceInput param_8 = i;\n        vec3 param_9 = _798;\n        _753 = fa_tangent_normal(param_8, param_9);\n    }\n    vec4 mrt = texture(fa_mr_tex_fa_smp, i.uv);\n    float param_10 = fa_mesh_fs_params[6].w;\n    float param_11 = 64.0;\n    vec3 param_12 = mrt.xyz;\n    float param_13 = fa_fix_of(param_10, param_11);\n    vec3 _315 = fa_tex_fix(param_12, param_13);\n    vec4 _801 = mrt;\n    _801.x = _315.x;\n    _801.y = _315.y;\n    _801.z = _315.z;\n    mrt = _801;\n    vec4 _345 = texture(fa_occlusion_tex_fa_smp, i.uv);\n    float param_14 = fa_mesh_fs_params[6].w;\n    float param_15 = 256.0;\n    vec3 param_16 = _345.xyz;\n    float param_17 = fa_fix_of(param_14, param_15);\n    vec3 _357 = fa_tex_fix(param_16, param_17);\n    float param_18 = fa_mesh_fs_params[6].w;\n    float param_19 = 4.0;\n    vec3 param_20 = texture(fa_emissive_tex_fa_smp, i.uv).xyz;\n    float param_21 = fa_fix_of(param_18, param_19);\n    vec3 _387 = fa_tex_fix(param_20, param_21);\n    float _758 = fa_mesh_fs_params[20].x;\n    float _759 = fa_mesh_fs_params[20].y;\n    float _762 = fa_mesh_fs_params[20].z;\n    float _761 = fa_mesh_fs_params[21].w;\n    float _764 = fa_mesh_fs_params[22].x;\n    if (fa_mesh_fs_params[22].z > 0.5)\n    {\n        if (mod(fa_mesh_fs_params[22].z, 2.0) > 0.5)\n        {\n            _758 *= _357.y;\n            _759 *= _357.z;\n            _761 *= _345.w;\n        }\n        if (fa_mesh_fs_params[22].z > 1.5)\n        {\n            _762 *= mrt.x;\n            _764 *= mrt.w;\n        }\n    }\n    return Surface(_243.xyz, _243.w, _753, clamp(fa_mesh_fs_params[5].x * _315.z, 0.0, 1.0), clamp(fa_mesh_fs_params[5].y * _315.y, 0.0500000007450580596923828125, 1.0), 1.0 + (fa_mesh_fs_params[6].y * (_357.x - 1.0)), fa_mesh_fs_params[3].xyz + (fa_mesh_fs_params[4].xyz * _387), _758, _759, fa_mesh_fs_params[21].xyz, _761, _762, fa_mesh_fs_params[20].w, _764, fa_mesh_fs_params[22].y, fa_mesh_fs_params[23].xyz);\n}\n\nvoid surface(SurfaceInput i, Surface s)\n{\n}\n\nvoid main()\n{\n    fa_inst_load();\n    vec3 _664 = normalize(fa_world_normal);\n    if (!gl_FrontFacing)\n    {\n        _664 = -_664;\n    }\n    vec3 _521 = normalize(fa_mesh_fs_params[0].xyz - fa_world_pos);\n    SurfaceInput param = SurfaceInput(fa_world_pos, _664, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    SurfaceInput param_1 = SurfaceInput(fa_world_pos, _664, fa_world_tangent, fa_uv, fa_vertex_color, _521, gl_FrontFacing);\n    Surface param_2 = fa_standard_surface(param);\n    surface(param_1, param_2);\n    vec3 _536 = normalize(param_2.normal);\n    vec3 _551 = normalize(vec3(dot(fa_pre_r0, _536), dot(fa_pre_r1, _536), dot(fa_pre_r2, _536)));\n    float _563 = _551.z;\n    vec2 e = _551.xy / vec2((abs(_551.x) + abs(_551.y)) + abs(_563));\n    if (_563 < 0.0)\n    {\n        e = (vec2(1.0) - abs(e.yx)) * vec2((e.x >= 0.0) ? 1.0 : (-1.0), (e.y >= 0.0) ? 1.0 : (-1.0));\n    }\n    fa_frag_color = vec4(min(fa_pre_depth, 60000.0), e, 1.0);\n}\n\n",
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
