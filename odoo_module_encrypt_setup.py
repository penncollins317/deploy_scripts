import os
import shutil
from glob import glob
from multiprocessing import freeze_support

from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize
from Cython.Distutils import build_ext

# 配置参数 - 只需修改这里即可适应不同项目
BASE_DIR = 'common_module_source'  # 基础目录（可修改为任何目录）
PACKAGE_NAME = 'odoo_filestore_oss'  # 主包名
# PACKAGE_NAME = 'alipay_integration'  # 主包名
STATIC_EXTS = ('.xml', '.js', '.css', '.csv', '.json', '.txt', '.html', '.png')  # 静态文件扩展名
NO_COMPILE_FILES = ('__manifest__.py', '__init__.py')  # 不编译的文件


# 动态路径计算
package_path = os.path.join(BASE_DIR, PACKAGE_NAME)
build_lib = os.path.join('build', 'libs', BASE_DIR)


class CustomBuildExt(build_ext):
    def initialize_options(self):
        super().initialize_options()
        self.inplace = False
        self.build_lib = build_lib

    def run(self):
        os.makedirs(self.build_lib, exist_ok=True)
        super().run()

        # 复制静态文件和排除编译的文件
        for root, _, files in os.walk(package_path):
            for file in files:
                src_path = os.path.join(root, file)
                rel_path = os.path.relpath(src_path, BASE_DIR)
                dest_path = os.path.join(self.build_lib, rel_path)

                if (file.endswith(STATIC_EXTS) or
                        file in NO_COMPILE_FILES or
                        not src_path.endswith('.py')):
                    os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                    shutil.copy2(src_path, dest_path)
        for root, dirs, files in os.walk(self.build_lib):
            for d in dirs:
                if d == '__pycache__':
                    shutil.rmtree(os.path.join(root, d), ignore_errors=True)
            for file in files:
                if file.endswith('.pyc'):
                    os.remove(os.path.join(root, file))
        print(f"构建完成！编译结果在 {self.build_lib} 目录")


# 获取需要编译的Python文件
py_files = [
    f for f in glob(os.path.join(package_path, '**', '*.py'), recursive=True)
    if os.path.basename(f) not in NO_COMPILE_FILES
]

# 生成Extension模块列表
extensions = []
for py_file in py_files:
    module_path = os.path.splitext(py_file)[0]  # 去掉.py
    module_name = module_path.replace(os.sep, '.')  # 转换为模块名
    # 移除BASE_DIR前缀（如果存在）
    if module_name.startswith(BASE_DIR.replace(os.sep, '.') + '.'):
        module_name = module_name[len(BASE_DIR) + 1:]
    extensions.append(Extension(module_name, [py_file]))

# 自动发现所有子包
packages = find_packages(where=BASE_DIR, include=[PACKAGE_NAME, f"{PACKAGE_NAME}.*"])
full_packages = [f"{BASE_DIR}.{pkg}" if not pkg.startswith(BASE_DIR) else pkg
                 for pkg in packages]
#  source /usr/local/python311/venvs/odoo17_311/bin/activate
# python odoo_module_encrypt_setup.py build_ext --parallel 4
# scp -r build/libs/kangli_project_source/eletronic_commerce  root@www.sfgyl.cc:/web/odoo17post/libs/kangli_project_source
if __name__ == '__main__':
    freeze_support()
    setup(
        name=PACKAGE_NAME,
        ext_modules=cythonize(
            extensions,
            compiler_directives={
                'language_level': "3",
                'embedsignature': True
            },
            build_dir=os.path.join('build', 'cython'),
            nthreads=os.cpu_count(),
        ),
        cmdclass={'build_ext': CustomBuildExt},
        packages=full_packages,
        package_dir={BASE_DIR: BASE_DIR},
        include_package_data=True,
        zip_safe=False
    )
