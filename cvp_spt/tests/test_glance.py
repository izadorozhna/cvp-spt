import pytest
import time
import subprocess
import cvp_spt.utils as utils


@pytest.fixture
def create_image():
    image_size_megabytes = utils.get_configuration().get("IMAGE_SIZE_MB")
    line = 'dd if=/dev/zero of=/tmp/image_mk_framework.dd bs=1M count={image_size}'.format(image_size=image_size_megabytes)
    subprocess.call(line, shell=True)
    yield
    # teardown
    subprocess.call('rm -f /tmp/image_mk_framework.dd'.split())
    subprocess.call('rm -f /tmp/image_mk_framework.download'.split())


def test_speed_glance(create_image, openstack_clients, record_property):
    """
    Simplified Performance Tests Download / upload lance
    1. Step download image
    2. Step upload image
    """
    image_size_megabytes = utils.get_configuration().get("IMAGE_SIZE_MB")
    image = openstack_clients.image.images.create(
        name="test_image",
        disk_format='iso',
        container_format='bare')

    start_time = time.time()
    openstack_clients.image.images.upload(
        image.id,
        image_data=open("/tmp/image_mk_framework.dd", 'rb'))
    end_time = time.time()

    speed_upload = image_size_megabytes / (end_time - start_time)

    start_time = time.time()
    with open("/tmp/image_mk_framework.download", 'wb') as image_file:
        for item in openstack_clients.image.images.data(image.id):
            image_file.write(item)
    end_time = time.time()

    speed_download = image_size_megabytes / (end_time - start_time)

    openstack_clients.image.images.delete(image.id)
    record_property("Upload", speed_upload)
    record_property("Download", speed_download)

    print "++++++++++++++++++++++++++++++++++++++++"
    print 'upload - {} Mb/s'.format(speed_upload)
    print 'download - {} Mb/s'.format(speed_download)
